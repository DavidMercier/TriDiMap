from pathlib import Path
import json
import pandas as pd

try:
    from GRANTA_MIScriptingToolkit import granta as mpy
except ImportError:
    mpy = None


# ======================================================================
# MI CLIENT
# ======================================================================
class MIClient:
    """
    High-level helper class for interacting with Granta MI using the
    legacy Scripting Toolkit (COM-based).

    Makes record creation, attribute writing, TABL population and
    flat/hierarchical workflows more consistent and robust.
    """

    # ------------------------------------------------------------------
    # Constructor
    # ------------------------------------------------------------------
    def __init__(self, server, username=None, password=None,
                 database=None, autologon=True):
        """
        Initialize connection to MI.

        Parameters
        ----------
        server : str
        username : str, optional
        password : str, optional
        database : str, optional
        autologon : bool, default=True
        """

        if mpy is None:
            raise RuntimeError(
                "Granta MI export requires the vendor-provided "
                "GRANTA MI Scripting Toolkit."
            )

        self.server = server
        self.username = username
        self.password = password
        self.database_key = database
        self.autologon = autologon

        self.mi = None
        self.db = None

        # --- 1. Try autologon ---
        if autologon:
            try:
                self.mi = mpy.connect(server, autologon=True)
                print("✔ MI autologon successful")
            except Exception as e:
                print(f"⚠ Autologon failed: {e}")

        # --- 2. Fallback to explicit login ---
        if self.mi is None:
            try:
                self.mi = mpy.connect(
                    server, user_name=username, password=password
                )
                print("✔ Connected using username/password")
            except Exception as e:
                raise RuntimeError(f"Failed to connect to MI: {e}")

        # --- 3. Open database ---
        if database:
            try:
                self.db = self.mi.get_db(db_key=database)
                self.db.set_unit_system("Metric")
                print(f"✔ Connected to DB '{database}' ({self.db.guid})")
            except Exception as e:
                raise RuntimeError(f"Failed to open database '{database}': {e}")

        self.default_table = None
        self.default_folder = None

    # ------------------------------------------------------------------
    # Config loader
    # ------------------------------------------------------------------
    @staticmethod
    def from_json(config_path):
        """
        Construct an MIClient from a JSON config file.

        The JSON must include:
            - server
            - username
            - password
            - database
            - autologon (optional)
            - default_table (optional)
            - default_folder (optional)
        """

        config_path = Path(config_path)
        if not config_path.exists():
            raise FileNotFoundError(f"MI config not found: {config_path}")

        with config_path.open("r") as f:
            cfg = json.load(f)

        client = MIClient(
            server=cfg.get("server"),
            username=cfg.get("username"),
            password=cfg.get("password"),
            database=cfg.get("database"),
            autologon=cfg.get("autologon", True),
        )

        client.default_table = cfg.get("default_table")
        client.default_folder = cfg.get("default_folder")

        return client

    # ------------------------------------------------------------------
    # Table fetch
    # ------------------------------------------------------------------
    def get_table(self, table_name):
        """Return MI table by name."""
        return self.db.get_table(table_name)

    # ------------------------------------------------------------------
    # Folder handling (hierarchical tables)
    # ------------------------------------------------------------------
    def ensure_folder(self, table, folder_name):
        """
        Find or create folder under a table.
        Compatible with legacy Scripting Toolkit behavior.
        """

        # Load existing folders
        try:
            folders = table.folders
        except Exception as e:
            raise RuntimeError(f"Cannot access folders on table '{table.name}': {e}")

        # Search existing
        for f in folders:
            if f.name == folder_name:
                return f

        # Create folder
        try:
            new_folder = table.add_folder(folder_name)
        except Exception as e:
            raise RuntimeError(f"Failed to create folder '{folder_name}': {e}")

        # Commit only the new folder
        try:
            new_folder = self.mi.update([new_folder])[0]
        except Exception:
            pass

        return new_folder

    # ------------------------------------------------------------------
    # Record creation under folder
    # ------------------------------------------------------------------
    def get_or_create_record(self, table, folder_record, name):
        """
        Get or create a record inside a specific folder.
        """

        for r in folder_record.records:
            if r.name == name:
                return r, True

        new_rec = folder_record.add_record(name)
        new_rec = self.mi.update([new_rec])[0]
        return new_rec, False

    # ------------------------------------------------------------------
    # Record creation at table root (flat tables)
    # ------------------------------------------------------------------
    def get_or_create_record_root(self, table, name):
        """
        Get or create a record at top level of table (no folder).
        """

        try:
            matches = table.search_for_records_by_name(name)
            if matches:
                return matches[0], True
        except Exception:
            pass

        # Create new
        try:
            new = table.create_record(name)
            new = self.mi.update([new])[0]
            return new, False
        except Exception as e:
            raise RuntimeError(f"Cannot create record '{name}': {e}")

    # ------------------------------------------------------------------
    # Record creation across DB (flat mode)
    # ------------------------------------------------------------------
    def get_or_create_record_flat(self, db, table, name):
        """
        Flat database search: find any record with matching name
        that belongs to this table. Otherwise create one.
        """

        try:
            matches = db.search_for_records_by_name(name)
            for r in matches:
                if r.table_name == table.name:
                    return r, True
        except Exception:
            pass

        try:
            new = table.create_record(name)
            new = self.mi.update([new])[0]
            return new, False
        except Exception as e:
            raise RuntimeError(f"Cannot create record '{name}': {e}")

    # ------------------------------------------------------------------
    # Attribute writing engine
    # ------------------------------------------------------------------
    def write_attributes(self, record, inputs, links=None):
        """
        Write attributes from an inputs DataFrame.
        Columns: "Inputs values"
        Index: attribute names

        Supports:
            - FILE
            - PICT
            - INPT  (integer)
            - REAL
            - TABL  (DataFrame → MI table)
            - HYPERLINK
            - TEXT / NOTE / STRING
            - DISC
        """

        results = []

        for attr_name in inputs.index:
            if attr_name not in record.attributes:
                print(f"⚠ Attribute '{attr_name}' not found in record → skipping")
                continue

            attribute = record.attributes[attr_name]
            raw = inputs.at[attr_name, "Inputs values"]

            # Handle DataFrame for TABL separately
            is_df = isinstance(raw, pd.DataFrame)

            if not is_df:
                if raw is None or raw == "" or str(raw).strip() in ("None", "[]"):
                    raw = None

            atype = attribute.type.upper()

            # ---------------------------
            # 1. FILE / PICT
            # ---------------------------
            if atype in ("FILE", "PICT"):
                if raw is None:
                    print(f"⚠ Missing file for {attr_name}")
                    continue
                path = Path(raw)
                if not path.exists():
                    print(f"⚠ File not found: {path}")
                    continue
                attribute.load(path)
                results.append(attribute)
                continue

            # ---------------------------
            # 2. INTEGER
            # ---------------------------
            if atype == "INPT":
                try:
                    attribute.value = int(raw)
                except Exception:
                    print(f"⚠ Invalid integer for {attr_name}, using 0")
                    attribute.value = 0
                results.append(attribute)
                continue

            # ---------------------------
            # 3. REAL
            # ---------------------------
            if atype == "REAL":
                try:
                    attribute.value = float(raw)
                except Exception:
                    print(f"⚠ Invalid REAL for {attr_name}, using 0.0")
                    attribute.value = 0.0
                results.append(attribute)
                continue

            # ---------------------------
            # 4. TABL
            # ---------------------------
            if atype == "TABL":
                df = raw
                tabl = attribute

                # Clear existing rows
                try:
                    tabl.clear_rows()
                except Exception as e:
                    print(f"⚠ clear_rows failed: {e}")

                mi_cols = list(tabl.columns)

                # Hardcoded schema expected in your DB
                type_map = {
                    "Phase": "TEXT",
                    "Cluster": "INTEGER",
                    "Volume (%)": "REAL",
                    "Hardness_Mean": "REAL",
                    "Hardness_Std": "REAL",
                    "Modulus_Mean": "REAL",
                    "Modulus_Std": "REAL",
                }

                for idx in range(len(df)):
                    tabl.add_row()
                    for col in df.columns:
                        if col not in mi_cols:
                            print(f"⚠ TABL column '{col}' not recognized → skipping")
                            continue

                        val = df[col].iloc[idx]
                        expected = type_map.get(col, "TEXT")

                        # Cast appropriately
                        try:
                            if expected == "INTEGER":
                                val = int(round(float(val)))
                            elif expected == "REAL":
                                val = float(val)
                            else:
                                val = "" if val is None else str(val)
                        except Exception:
                            val = 0 if expected in ("REAL", "INTEGER") else ""

                        tabl[col, idx] = val

                results.append(attribute)
                continue

            # ---------------------------
            # 5. HYPERLINK
            # ---------------------------
            if atype == "HYPERLINK":
                if raw is None:
                    print(f"⚠ Missing hyperlink for {attr_name}")
                    continue
                attribute.value = str(raw)
                results.append(attribute)
                continue

            # ---------------------------
            # 6. TEXT-LIKE types
            # ---------------------------
            if atype in ("TEXT", "NOTE", "STRING"):
                attribute.value = "(none)" if raw is None else str(raw)
                results.append(attribute)
                continue

            # ---------------------------
            # 7. DISC (discrete choice)
            # ---------------------------
            if atype == "DISC":
                if raw is None:
                    print(f"⚠ Empty DISC for {attr_name}")
                    continue
                attribute.value = raw
                results.append(attribute)
                continue

            # ---------------------------
            # 8. Default generic assignment
            # ---------------------------
            try:
                attribute.value = raw
                results.append(attribute)
            except Exception as e:
                print(f"⚠ Could not assign '{attr_name}': {e}")

        return results

    # ------------------------------------------------------------------
    # Commit attribute changes
    # ------------------------------------------------------------------
    def update_record(self, record, results):
        """
        Commit attributes to MI record.
        Only modified attributes are passed in `results`.
        """

        record.set_attributes(results)

        print("\n=== DEBUG: Attributes before commit ===")
        for name, attr in record.attributes.items():
            try:
                print(f"{name}: {attr.value!r}")
            except Exception:
                print(f"{name}: <non-scalar>")

        updated = self.mi.update([record])[0]
        return updated

    # ------------------------------------------------------------------
    # Clear specific attributes
    # ------------------------------------------------------------------
    def clear_record(self, record, record_name, attribute_list):
        """
        Clear only the specified attributes from a record.
        Compatible with legacy MI API.
        """

        to_clear = []

        for attr_name in attribute_list:
            if attr_name not in record.attributes:
                print(f"⚠ Attribute '{attr_name}' not in record '{record_name}'")
                continue

            try:
                to_clear.append(record.attributes[attr_name])
            except Exception as e:
                print(f"⚠ Cannot access '{attr_name}': {e}")

        if not to_clear:
            print(f"ℹ No attributes cleared for '{record_name}'")
            return record

        try:
            record.clear_attributes(to_clear)
        except Exception as e:
            print(f"❌ Clearing attributes failed: {e}")
            return record

        try:
            record = self.mi.update([record])[0]
            print(f"✔ Cleared attributes for '{record_name}'")
        except Exception as e:
            print(f"❌ Failed to update '{record_name}': {e}")

        return record

    # ------------------------------------------------------------------
    # Debug schema printer
    # ------------------------------------------------------------------
    def print_schema(self, table_name):
        """
        Print the schema (attribute names, types, meta-attributes)
        of a given table.
        """

        table = self.get_table(table_name)

        print(f"\n=== SCHEMA FOR TABLE: {table_name} ===")
        for name, attr in table.attributes.items():
            print(f"{name:35s} type={attr.type}")
            for mname, meta in attr.meta_attributes.items():
                print(f"    META: {mname:30s} type={meta.type}")
        print("=== END SCHEMA ===")
