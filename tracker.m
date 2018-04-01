function [positions, time] = tracker(video_path, img_files, pos, target_sz, ...
	padding, kernel, lambda, output_sigma_factor, interp_factor, cell_size, ...
	features, show_visualization)
%TRACKER Kernelized/Dual Correlation Filter (KCF/DCF) tracking.
%                                                                          �������ں�/˫����˲�����KCF / DCF�����١�
%   This function implements the pipeline for tracking with the KCF (by
%   choosing a non-linear kernel) and DCF (by choosing a linear kernel).
%                                                          �ú���ʵ���˸���KCF��ͨ��ѡ��������ںˣ���DCF��ͨ��ѡ�������ںˣ�����ˮ�ߡ�
%   It is meant to be called by the interface function RUN_TRACKER, which
%   sets up the parameters and loads the video information.
%                                                                          ����ζ���ɽӿں���RUN_TRACKER���ã��ú������ò�����������Ƶ��Ϣ��
%   Parameters:                                                             ����
%     VIDEO_PATH is the location of the image files (must end with a slash
%      '/' or '\').                                                        VIDEO_PATH��ͼ���ļ���λ��
%     IMG_FILES is a cell array of image file names.                       IMG_FILES��ͼ���ļ����Ƶĵ�Ԫ���С�
%     POS and TARGET_SZ are the initial position and size of the target
%      (both in format [rows, columns]).                                   POS��TARGET_SZ��Ŀ��ĳ�ʼλ�úʹ�С����ʽ[�У���]��
%     PADDING is the additional tracked region, for context, relative to 
%      the target size.                                                    PADDING�������Ŀ��ߴ���Ե������ĸ��Ӹ�������
%     KERNEL is a struct describing the kernel. The field TYPE must be one   KERNEL�������ں˵Ľṹ��
%      of 'gaussian', 'polynomial' or 'linear'. The optional fields SIGMA,   �ֶ�TYPE������'��˹'��'����ʽ'��'����'֮һ��
%      POLY_A and POLY_B are the parameters for the Gaussian and Polynomial  ��ѡ�ֶ�SIGMA��POLY_A��POLY_B�Ǹ�˹�Ͷ���ʽ�ں˵Ĳ�����
%      kernels.
%     OUTPUT_SIGMA_FACTOR is the spatial bandwidth of the regression
%      target, relative to the target size.                                 OUTPUT_SIGMA_FACTOR�ǻع�Ŀ�������Ŀ���С�Ŀռ����
%     INTERP_FACTOR is the adaptation rate of the tracker.                  INTERP_FACTOR�Ǹ�����������Ӧ���ʡ�
%     CELL_SIZE is the number of pixels per cell (must be 1 if using raw
%      pixels).                                                             CELL_SIZE��ÿ����Ԫ����������������ʹ��ԭʼ���أ������Ϊ1����
%     FEATURES is a struct describing the used features (see GET_FEATURES). FEATURES������ʹ�������Ľṹ�������GET_FEATURES����
%     SHOW_VISUALIZATION will show an interactive video if set to true.     �������Ϊtrue��SHOW_VISUALIZATION����ʾһ������ʽ��Ƶ��
%
%   Outputs:                                                                ���                                                               
%    POSITIONS is an Nx2 matrix of target positions over time (in the
%     format [rows, columns]).                                              POSITIONS����ʱ��仯��Ŀ��λ�õ�N��2���󣨸�ʽΪ[�У���]����
%    TIME is the tracker execution time, without video loading/rendering.   TIME��׷������ִ��ʱ�䣬û����Ƶ����/��Ⱦ��
%
%   Joao F. Henriques, 2014


	%if the target is large, lower the resolution, we don't need that much
	%detail                                                                ���Ŀ��ܴ󣬽��ͷֱ��ʣ����ǲ���Ҫ̫��ϸ��
	resize_image = (sqrt(prod(target_sz)) >= 100);  %diagonal size >= threshold    �Խ��ߴ�С> =��ֵ
	if resize_image,
		pos = floor(pos / 2);                                              %Ŀ��ߴ����ͽ�����С1/2
		target_sz = floor(target_sz / 2);                                   %������ʾ���õ�target_sz�����ڼ���Ķ���window_sz
	end


	%window size, taking padding into account                              ���ڴ�С���������
	window_sz = floor(target_sz * (1 + padding));                          %floor����ȡ����Ŀ���������չ1.5����Ϊwindow_sz
	                                                                       %�������еĴ�����window_sz��������Ŀ��ͱ���
% 	%we could choose a size that is a power of two, for better FFT          ���ǿ���ѡ��2�Ĵ��ݵĴ�С���Ի�ø��õ�FFT
% 	%performance. in practice it is slower, due to the larger window size.  ������ʵ���з������������ڳߴ�̫�� 
% 	
% 	window_sz = 2 .^ nextpow2(window_sz);

	
	%create regression labels, gaussian shaped, with a bandwidth
	%�����ع��ǩ����˹��״��������Ŀ��ĳߴ�ɱ�����Ŀ��ߴ�Խ�󣬴���Խ��
	%proportional to target size
	output_sigma = sqrt(prod(target_sz)) * output_sigma_factor / cell_size;%prod��������Ԫ�ص����˻�
    %output_sigma Ϊ����delta��  cell_sizeÿһ��ϸ�������ص�������HOG),������HOG��Ϊ1
	yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / cell_size)));%fft2 2ά��ɢ����Ҷ�任��yf��Ƶ���ϵĻع�ֵ

	%store pre-computed cosine window                                      �洢Ԥ�ȼ�������Ҵ���
	cos_window = hann(size(yf,1)) * hann(size(yf,2))';	                   %hann��������ʹ��yf�ĳߴ���������Ӧ�����Ҵ�
	%�������Ҵ���size(yf,1)����������size(yf,2)��������
	
	if show_visualization,  %create video interface                        ������Ƶ�������棨������̵Ŀ��ӻ���
		update_visualization = show_video(img_files, video_path, resize_image);
	end
	
	
	%note: variables ending with 'f' are in the Fourier domain.
	%��f�Ķ���Ƶ���ϵ�

	time = 0;  %to calculate FPS                                            Ϊ�˼���FPS
	positions = zeros(numel(img_files), 2);  %to calculate precision       ��ʼ��n��2�еľ����������ÿһ֡�������λ��
                     %numel(img_files)��Ƶ��֡��
	for frame = 1:numel(img_files),
		%load image                                                         ��ͼ��
		im = imread([video_path img_files{frame}]);                        %��ȡһ֡ͼ��
		if size(im,3) > 1,
			im = rgb2gray(im);                                             %�Ѳ�ɫͼת��Ϊ�Ҷ�ͼ
		end
		if resize_image,
			im = imresize(im, 0.5);                                        %��Ŀ����󣬰�����ͼ��Ϊԭ����1/2��С
		end

		tic()                                                              %��ʼ��ʱ����toc�������ʹ��

        if frame > 1,
			%obtain a subwindow for detection at the position from last    �����һ֡��λ�û�����ڼ����Ӵ��ڣ�
			%frame, and convert to Fourier domain (its size is unchanged)  ��ת��������Ҷ�����С���䣩
			patch = get_subwindow(im, pos, window_sz);
			zf = fft2(get_features(patch, features, cell_size, cos_window));%zf�ǲ�������
			
			%calculate response of the classifier at all shifts
			%�����������������ѭ��λ�ƺ����������Ӧ
			switch kernel.type                                             %ѡ��˵�����
			case 'gaussian',
				kzf = gaussian_correlation(zf, model_xf, kernel.sigma);    %ͨ���Բ��������ĺ˱任��õ�kzf
			case 'polynomial',
				kzf = polynomial_correlation(zf, model_xf, kernel.poly_a, kernel.poly_b);
			case 'linear',
				kzf = linear_correlation(zf, model_xf);
			end
			response = real(ifft2(model_alphaf .* kzf));  %equation for fast detection������Ӧ
%real->����ʵ������������ifft2->������Ҷ�任��model_alphaf->ģ�ͣ�* ->Ԫ�ص��

			%target location is at the maximum response. we must take into    Ŀ��λ�ô��������Ӧ(��Щ��Ӧ�ܶ���ʼ)��
			%account the fact that, if the target doesn't move, the peak      ���Ǳ��뿼�ǵ�����һ����ʵ��
			%will appear at the top-left corner, not at the center (this is   ���Ŀ��û���ƶ���
			%discussed in the paper). the responses wrap around cyclically.   ��ֵ�����������Ͻǣ����������ģ��������������۹�����
			[vert_delta, horiz_delta] = find(response == max(response(:)), 1);%�ҵ���Ӧ����λ��
			if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis  �Ƶ�����ĸ���ռ�
				vert_delta = vert_delta - size(zf,1);
			end
			if horiz_delta > size(zf,2) / 2,  %same for horizontal axis       �������ͬ
				horiz_delta = horiz_delta - size(zf,2);
			end
			pos = pos + cell_size * [vert_delta - 1, horiz_delta - 1];     %���³�Ŀ�����λ��
        end
%if frame>1  �Ľ�β����
        
		%obtain a subwindow for training at newly estimated target position���¹��Ƶ�Ŀ��λ�û��һ������ѵ�����Ӵ���
		patch = get_subwindow(im, pos, window_sz);                         %��ȡĿ���λ�úʹ��ڴ�С
		xf = fft2(get_features(patch, features, cell_size, cos_window));   %���µĽ������ѵ��������

		%Kernel Ridge Regression, calculate alphas (in Fourier domain)
		%�ں���ع飬���ڸ���Ҷ�򣩼���alphas(Ȩֵ)
		switch kernel.type
		case 'gaussian',
			kf = gaussian_correlation(xf, xf, kernel.sigma);
		case 'polynomial',
			kf = polynomial_correlation(xf, xf, kernel.poly_a, kernel.poly_b);
		case 'linear',
			kf = linear_correlation(xf, xf);
		end
		alphaf = yf ./ (kf + lambda);   %equation for fast training        ѵ�����ÿ��������Ӧ��Ȩֵ

        %����ģ���Ȩֵ
		if frame == 1,  %first frame, train with a single image            ��һ֡���õ���ͼ��ѵ����
			model_alphaf = alphaf;                                         %��һ֡�о�ֱ����ѵ������Ȩֵ��ģ��
			model_xf = xf;
		else
			%subsequent frames, interpolate model                          ����֡����ֵģ��
			model_alphaf = (1 - interp_factor) * model_alphaf + interp_factor * alphaf;%����֡�еĸ���ʹ�ñ�֡��ǰһ֡�н���ļ�Ȩ
			model_xf = (1 - interp_factor) * model_xf + interp_factor * xf;
        end                           %model_xf ��һ֡ ��  interp_factor * xf ��һ֡��  

		%save position and timing
		positions(frame,:) = pos;                                          %����ÿһ֡�е�Ŀ��λ��
		time = time + toc();                                               %���洦�����ĵ�ʱ��

		%visualization                                                     ��ÿһ֡�Ľ����ʾ����
		if show_visualization,
			box = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];    
			stop = update_visualization(frame, box);
			if stop, break, end  %user pressed Esc, stop early             �û���Esc����ǰֹͣ
			
			drawnow
% 			pause(0.05) ��ͣ %uncomment to run slowerȡ������ע�ͣ������н���
		end
		
    end%  �͵�80�е�for ���һ��end of for ѭ��

	if resize_image,                                                       %��֮ǰ��ͼ����С�ˣ���λ�õ����껻���ȥ
		positions = positions * 2;
	end
end

