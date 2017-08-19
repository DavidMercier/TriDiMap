function [ output_args ] = Untitled2( input_args )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

 if gui.config.plotImage
        %% Plot figure
        gui.data.picture_raw = flipud(imread(gui.config.imageRaw_path));
        gui.data.picture_rawBW = flipud(imread(gui.config.imageRawBW_path));
        gui.data.picture_scaled = flipud(imread(gui.config.imageScaled_path));
        
        xData_interp = 0:(gui.config.N_XStep_default-1)*gui.config.XStep_default/size(gui.data.picture_raw,1):(gui.config.N_XStep_default-1) * gui.config.XStep_default;
        yData_interp = xData_interp;
        
        scrsize = get(0, 'ScreenSize'); % Get screen size
        WX = 0.15 * scrsize(3); % X Position (bottom)
        WY = 0.10 * scrsize(4); % Y Position (left)
        WW = 0.70 * scrsize(3); % Width
        WH = 0.80 * scrsize(4); % Height
        
        %         f(3) = figure('position', [WX, WY, WW, WH]);
        %         hi(3) = image(gui.data.picture_raw);
        %         hold on;
        %         axisMap([], 'Raw microstructural map', gui.config.FontSizeVal, ...
        %             (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
        %             (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        %         hold off;
        
        f(4) = figure('position', [WX, WY, WW, WH]);
        hi(4) = imagesc(gui.data.picture_raw, 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(flipud(gray), 'Raw microstructural map (grayscale)', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        hold off;
        
        % Use im2bw if ImageProcessing Toolbox
        f(5) = figure('position', [WX, WY, WW, WH]);
        hi(5) = imagesc(gui.data.picture_rawBW, 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Binary microstructural map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.Legend, gui.config.FontSizeVal);
        hold off;
        fracBW = sum(sum(gui.data.picture_rawBW))/(size(gui.data.picture_rawBW,1)*size(gui.data.picture_rawBW,2)*255);
        display('Fraction of particles (raw data):');
        disp(fracBW);
        display('Fraction of matrix (raw data):');
        disp(1-fracBW);
        
        f(6) = figure('position', [WX, WY, WW, WH]);
        hi(6) = imagesc(gui.data.picture_scaled, 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Microstructural map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.Legend, gui.config.FontSizeVal);
        hold off;
        fracBW = sum(sum(gui.data.picture_scaled))/(size(gui.data.picture_scaled,1)*size(gui.data.picture_scaled,2)*255);
        display('Fraction of particles (pixelized data):');
        disp(fracBW);
        display('Fraction of matrix (pixelized data):');
        disp(1-fracBW);
        
        %% Calculation of maps difference
        % Display % of error - If 0, then perfect match and if 1 perfect mismatch.
        
        % Difference between microstructure map and YM map
        %gui.results.diffYM = (rot90(YM_binarized) == flipud(gui.data.picture_scaled));
        gui.results.diffYM = rot90(int8(YM_binarized)) - flipud(int8(gui.data.picture_scaled));
        gui.results.diffYM(gui.results.diffYM~=0)=1;
        diff_YM_error = sum(sum(gui.results.diffYM))/(gui.config.N_XStep_default * gui.config.N_YStep_default);
        display(diff_YM_error);
        f(7) = figure('position', [WX, WY, WW, WH]);
        hi(7) = imagesc(flipud(gui.results.diffYM), 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Phase-Elastic modulus difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
        hold off;
        
        % Difference between microstructure map and H map
        %gui.results.diffH = (rot90(H_binarized) == flipud(gui.data.picture_scaled));
        gui.results.diffH = rot90(int8(H_binarized)) - flipud(int8(gui.data.picture_scaled));
        gui.results.diffH(gui.results.diffH~=0)=1;
        diff_H_error = sum(sum(gui.results.diffH))/(gui.config.N_XStep_default * gui.config.N_YStep_default);
        display(diff_H_error);
        f(8) = figure('position', [WX, WY, WW, WH]);
        hi(8) = imagesc(flipud(gui.results.diffH), 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Phase-Hardness difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
        hold off;
        
        % Difference between YM map and H map
        gui.results.diff_EH = rot90(int8(YM_binarized)) - rot90(int8(H_binarized));
        gui.results.diff_EH(gui.results.diff_EH~=0)=1;
        diff_EH_error = sum(sum(gui.results.diff_EH))/(gui.config.N_XStep_default * gui.config.N_YStep_default);
        display(diff_EH_error);
        f(9) = figure('position', [WX, WY, WW, WH]);
        hi(9) = imagesc(flipud(gui.results.diff_EH), 'XData',xData_interp,'YData',yData_interp);
        hold on;
        axisMap(gray, 'Elastic modulus-Hardness difference map', gui.config.FontSizeVal, ...
            (gui.config.N_XStep_default-1)*gui.config.XStep_default, ...
            (gui.config.N_YStep_default-1)*gui.config.YStep_default);
        legendBinaryMap('w', 'k', 's', 's', gui.config.LegendMatch, gui.config.FontSizeVal);
        hold off;
        
        % Difference between microstructure map and YM map (only black pixels)
        for ii = 1:size(YM_binarized,1)
            for jj = 1:size(YM_binarized,2)
                if rot90(int8(YM_binarized(ii,jj))) == 127 && flipud(int8(gui.data.picture_scaled(ii,jj))) == 127
                    gui.results.diffYM2(ii,jj) = 0;
                else
                    gui.results.diffYM2(ii,jj) = 1;
                end
            end
        end
        diff_YM_error2 = sum(sum(abs(gui.results.diffYM2-1)))/(sum(sum(gui.data.picture_scaled/255)));
        display(diff_YM_error2);
        
        % Difference between microstructure map and H map (only black pixels)
        for ii = 1:size(H_binarized,1)
            for jj = 1:size(H_binarized,2)
                if rot90(int8(H_binarized(ii,jj))) == 127 && flipud(int8(gui.data.picture_scaled(ii,jj))) == 127
                    gui.results.diffH2(ii,jj) = 0;
                else
                    gui.results.diffH2(ii,jj) = 1;
                end
            end
        end
        diff_H_error2 = sum(sum(abs(gui.results.diffH2-1)))/(sum(sum(gui.data.picture_scaled/255)));
        display(diff_H_error2);
 end
    
end

