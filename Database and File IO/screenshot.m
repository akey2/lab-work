%%% Stolen mostly from IMCLIPBOARD on the File Exchange (Jiro Doke)

function data = screenshot

% Check if Java installed
error(javachk('awt', 'screenshot'));

% Import necessary Java classes
import java.awt.Toolkit
import java.awt.image.BufferedImage
import java.awt.datatransfer.DataFlavor

% Get System Clipboard object (java.awt.Toolkit)
cb = Toolkit.getDefaultToolkit.getSystemClipboard();

% Grab previous clipboard data
try
    % Attempt to retrieve image data from system clipboard. If there is no
    % image data, it will throw an exception.
    prevdata = Buffer2Im(cb.getData(DataFlavor.imageFlavor));
catch %#ok<CTCH>
    prevdata = [];
end

% Run Snipping Tool app
!snippingtool

% Grab clipboard data
try
    % Attempt to retrieve image data from system clipboard. If there is no
    % image data, it will throw an exception.
    data = Buffer2Im(cb.getData(DataFlavor.imageFlavor));
catch %#ok<CTCH>
    data = [];
    return;
end

if (~isempty(prevdata) && all(size(prevdata) == size(data), 'all') && all(data==prevdata,'all'))
    data = [];
end


end



function im = Buffer2Im(imBuffer)

im = imBuffer.getRGB(0, 0, imBuffer.getWidth, imBuffer.getHeight, [], 0, imBuffer.getWidth);
% "im" is an INT32 array, where each value contains 4 bytes of information
% (Blue, Green, Red, Alpha). Alpha is not used.

% type cast INT32 to UINT8 (--> 4 times as many elements)
im = typecast(im, 'uint8');

% Reshape to 4xWxH
im = reshape(im, [4, imBuffer.getWidth, imBuffer.getHeight]);

% Remove Alpha information (4th row) because it is not used
im = im(1:3, :, :);

% Convert to HxWx3 array
im = permute(im, [3 2 1]);

% Convert color space order to R-G-B
im = im(:, :, [3 2 1]);

end