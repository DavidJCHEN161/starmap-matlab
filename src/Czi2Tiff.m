function Czi2Tiff(cziFile, outputDir)
% CZI2TIFF Convert Zeiss .czi files into per-channel TIFF stacks.
%   Czi2Tiff(cziFile, outputDir) uses the Bio-Formats toolbox to read the
%   specified CZI file and writes each series (round) and channel as a
%   multi-page TIFF that can be loaded by the STARMAP pipeline. The output
%   directory will contain folders named round1, round2, ... with files
%   ch1.tif, ch2.tif, etc.
%
%   Requires Bio-Formats (https://www.openmicroscopy.org/bio-formats/)
%   functions such as bfGetReader and bfGetPlane on the MATLAB path.
%
%   Example:
%       Czi2Tiff('sample.czi', '/data/converted');

    if nargin < 2
        outputDir = fileparts(cziFile);
    end

    reader = bfGetReader(cziFile);
    seriesCount = reader.getSeriesCount();

    for s = 1:seriesCount
        reader.setSeries(s - 1); % Bio-Formats uses 0-based indices
        zCount = reader.getSizeZ();
        cCount = reader.getSizeC();
        tCount = reader.getSizeT();
        height = reader.getSizeY();
        width = reader.getSizeX();

        roundDir = fullfile(outputDir, sprintf('round%d', s));
        if ~exist(roundDir, 'dir')
            mkdir(roundDir);
        end

        for c = 1:cCount
            pixelClass = class(bfGetPlane(reader, 1));
            stack = zeros(height, width, zCount * tCount, pixelClass);
            plane = 1;
            for t = 1:tCount
                for z = 1:zCount
                    index = reader.getIndex(z - 1, c - 1, t - 1) + 1;
                    stack(:, :, plane) = bfGetPlane(reader, index);
                    plane = plane + 1;
                end
            end

            outName = fullfile(roundDir, sprintf('ch%d.tif', c));
            for k = 1:size(stack, 3)
                if k == 1
                    imwrite(stack(:, :, k), outName, 'tif', 'Compression', 'none');
                else
                    imwrite(stack(:, :, k), outName, 'tif', 'WriteMode', 'append', 'Compression', 'none');
                end
            end
        end
    end

    reader.close();
end

