function gui = TriDiMap_cacheKamm(gui, E, H)
c = gui.config;
key = struct('E', E, 'H', H, 'order', c.mlOrder);
if ~isfield(gui, 'kamm') || ~isequaln(gui.kamm.key, key)
    gui.kamm = struct('key', key, 'maps', TriDiMap_kamm(E, H, c.mlOrder));
end
[x, y] = ndgrid((c.MinXCrop-1+(0:size(H, 1)-1))*c.XStep, ...
    (c.MinYCrop-1+(0:size(H, 2)-1))*c.YStep);
gui.kamm.coordinates = [x(:), y(:)];
end
