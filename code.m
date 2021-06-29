%% Convert video to images matrix

% video path
video_filepath = 'data/egermjv-2016-08-16.webm';
% video reader object
vidObj = VideoReader(video_filepath);

% number of all frames in the video
all_frames = vidObj.NumberOfFrames;
% fps
frame_rate = vidObj.FrameRate;

% we are going to read two frames each seconds
% pick a frame every 'reading_interval' frames
reading_interval = floor(frame_rate / 2);
% number of frames we are going to read
num_frames = floor(all_frames / reading_interval);

% due to high quality and expensive computation and memory usage needed
% we are going to scale frame diemenstions down 0.5 time
scaling_factor = 0.5;
img = read(vidObj, 1);
img = imresize(img, scaling_factor);

frame_height = size(img, 1);
frame_width = size(img, 2);
frame_depth = size(img, 3);

% initialize (prelocate) needed matrix to store all extracted frames
imgs = zeros(num_frames, frame_height, frame_width, frame_depth, 'uint8');
% read frames from the video
for i=1:num_frames
    img = read(vidObj, (i-1) * reading_interval + 1);
    img = imresize(img, scaling_factor);
    imgs(i, :, :, :) = img;
    fprintf('%d out of %d frames are read\n', i, num_frames);
end

%% Images matrix dimensions
size(imgs)

%% Show image
img = squeeze(imgs(190, :, :, :));
imshow(img);

%% Show histogram before normalization
img_r = img(:,:,1);
histogram(img_r(:));

%% Normalization

% normalized images matrix should be double matrix
normalized_imgs = double(imgs);
% initialize (prelocate) normalized_means and normalized_stds to store
% means and stds before normalization
normalized_means = zeros(num_frames, frame_depth, 'double');
normalized_stds = zeros(num_frames, frame_depth, 'double');


for i=1:num_frames
    for d=1:frame_depth
        img = normalized_imgs(i, :, :, d);
        % convert image matrix to vector
        img = img(:);
        % compute the mean
        m = mean(img);
        % translate pixel values to have a zero mean
        img = img - m;
        % compute the std
        s = std(img);
        % scale pixel values to have a unit variance
        img = img / s;
        % store the normlized image, means and std
        normalized_imgs(i, :, :, d) = reshape(img, 1, 540, 960);
        normalized_means(i, d) = m;
        normalized_stds(i, d) = s;
    end
end

%% Histogram of the normalized image
histogram(normalized_imgs(1, :, :, 1))

%% Extract the background

% number of consecutive frames to process and extract background from 
filter_size = 30;
% number of frame to start filtering from (offset)
start_frame = 80; % e.g. to get background in night you can set start_frame = 170

% split 'filter_size' of consecutive frames starting from 'start_frame'
consecutive_frames = normalized_imgs(start_frame:start_frame + filter_size, :, :, :);
% apply median function
% the output is one image with the same diementions of the original images
bg_normalized = median(consecutive_frames);
% eliminate the dimentions which consist of one element
bg_normalized = squeeze(bg_normalized);

% apply the same median function on the same means and stds
bg_mean = median(normalized_means(start_frame:start_frame + filter_size, :));
bg_std = median(normalized_stds(start_frame:start_frame + filter_size, :));

% restore the RGB image 
% scale pixels to the original std
% translate pixles to the original mean
bg_normalized(:, :, 1) = bg_normalized(:, :, 1) * bg_std(1, 1) + bg_mean(1, 1);
bg_normalized(:, :, 2) = bg_normalized(:, :, 2) * bg_std(1, 2) + bg_mean(1, 2);
bg_normalized(:, :, 3) = bg_normalized(:, :, 3) * bg_std(1, 3) + bg_mean(1, 3);

% convert double matrix to uint8 matrix
bg = uint8(round(bg_normalized));

% show the background
imshow(bg);

%% Save background
imwrite(bg, 'data/bg.jpg');
