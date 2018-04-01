function update_visualization_func = show_video(img_files, video_path, resize_image)
%SHOW_VIDEO
%   Visualizes a tracker in an interactive figure, given a cell array of
%   image file names, their path, and whether to resize the images to
%   half size or not.�ڽ���ʽͼ������ʾ������������ͼ���ļ����Ƶĵ�Ԫ���У�·���Լ��Ƿ�ͼ���С����Ϊһ�롣
%
%   This function returns an UPDATE_VISUALIZATION function handle, that    �ú�������һ��UPDATE_VISUALIZATION���������
%   can be called with a frame number and a bounding box [x, y, width,     һ���������֡�Ľ����
%   height], as soon as the results for a new frame have been calculated.  �þ���Ϳ�����֡�źͱ߽��[x��y��width��height]���á�
%   This way, your results are shown in real-time, but they are also       ���������Ľ����ʱ��ʾ��
%   remembered so you can navigate and inspect the video afterwards.       ��������Ҳ�ᱻ��ס���Ա��Ժ���Ե����������Ƶ��
%   Press 'Esc' to send a stop signal (returned by UPDATE_VISUALIZATION).  ��'Esc'����һ��ֹͣ�źţ���UPDATE_VISUALIZATION���أ���
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	%store one instance per frame                                          ÿ֡�洢һ��ʵ��
	num_frames = numel(img_files);                                         %numel������ͼ���е����ظ���
	boxes = cell(num_frames,1);                                            %cell������һ��num_frames*1��cell����

	%create window                                                         ��������
	[fig_h, axes_h, unused, scroll] = videofig(num_frames, @redraw, [], [], @on_key_press);  %#ok, unused outputs
	set(fig_h, 'Number','off', 'Name', ['Tracker - ' video_path])          %set������ͼ������
	axis off;        %axis������������
	
	%image and rectangle handles start empty, they are initialized later   ͼ��;���handle��ʼΪ�գ��������Ժ󱻳�ʼ��
	im_h = [];
	rect_h = [];
	
	update_visualization_func = @update_visualization;                     %@�������ڶ��庯������Ĳ�������
	stop_tracker = false;                                                  %�����������һ�ֱ������������ڴ��κ͸�ֵ��Ҳ�ǿ��Ե���������һ��ʹ�á�
	

	function stop = update_visualization(frame, box)
		%store the tracker instance for one frame, and show it. returns    ��������ʵ���洢һ֡������ʾ����
		%true if processing should stop (user pressed 'Esc').              �������ֹͣ���û���'Esc'�����򷵻�true��
		boxes{frame} = box;                                                %�洢֡
		scroll(frame);                                                     %��ʾ֡
		stop = stop_tracker;
	end

	function redraw(frame)
		%render main image                                                 ��Ⱦ��ͼ��
		im = imread([video_path img_files{frame}]);                        %imread�����ڶ�ȡͼƬ�ļ��е�����
		if size(im,3) > 1,                                                 %3��ʾΪRGB�����ͼ��Ϊ��ɫͼ������ת��Ϊ�Ҷ�ͼ
			im = rgb2gray(im);
		end
		if resize_image,                                                   %����ͼ���С
			im = imresize(im, 0.5);
		end
		
		if isempty(im_h),  %create image                                   ���û��ͼ�����룬�򴴽�ͼ��
			im_h = imshow(im, 'Border','tight', 'InitialMag',200, 'Parent',axes_h);
		else  %just update it                                              �����ͼ�������������
			set(im_h, 'CData', im)
		end
		
		%render target bounding box for this frame                         Ϊ��֡��ȾĿ��߽��
		if isempty(rect_h),  %create it for the first time                 ���û�о��α߽�����һ�δ�����
			rect_h = rectangle('Position',[0,0,1,1], 'EdgeColor','g', 'Parent',axes_h);
            %rectangle:���ƾ���ͼ�Σ��߿���ɫ��
		end
		if ~isempty(boxes{frame}),                                         %����洢��֡��Ϊ0��boxes{frame}Ӧ���Ǹ����꣩
			set(rect_h, 'Visible', 'on', 'Position', boxes{frame});
		else
			set(rect_h, 'Visible', 'off');
		end
	end

	function on_key_press(key)
		if strcmp(key, 'escape'),  %stop on 'Esc'
			stop_tracker = true;
		end
	end

end

