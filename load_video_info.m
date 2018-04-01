function [img_files, pos, target_sz, ground_truth, video_path] = load_video_info(base_path, video)
%LOAD_VIDEO_INFO
%   Loads all the relevant information for the video in the given path:    �ڸ���·���м�����Ƶ�����������Ϣ��
%   the list of image files (cell array of strings), initial position      ͼ���ļ��б��ַ�����Ԫ�����飩��
%   (1x2), target size (1x2), the ground truth information for precision   ��ʼλ�ã�1x2����Ŀ���С��1x2���� ��ȷ��ground truth��Ϣ
%   calculations (Nx2, for N frames), and the path where the images are    ���㣨Nx2��N֡���Լ�ͼ�����ڵ�·����
%   located. The ordering of coordinates and sizes is always [y, x].       ����ʹ�С����������[y��x]��    
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/


	%see if there's a suffix, specifying one of multiple targets, for      �鿴�Ƿ��к�׺��ָ�����Ŀ���е�һ����
	%example the dot and number in 'Jogging.1' or 'Jogging.2'.             ���硰Jogging.1����Jogging.2���еĵ�����֡�
	if numel(video) >= 2 && video(end-1) == '.' && ~isnan(str2double(video(end))),
		suffix = video(end-1:end);  %remember the suffix                   ��ס��׺
		video = video(1:end-2);  %remove it from the video name            ����Ƶ������ɾ����
	else
		suffix = '';
	end

	%full path to the video's files                                        ��Ƶ�ļ�������·��
	if base_path(end) ~= '/' && base_path(end) ~= '\',
		base_path(end+1) = '/';
	end
	video_path = [base_path video '/'];

	%try to load ground truth from text file (Benchmark's format)          ���Դ��ı��ļ�����ground truth����׼��ʽ��
	filename = [video_path 'groundtruth_rect' suffix '.txt'];
	f = fopen(filename);
	assert(f ~= -1, ['No initial position or ground truth to load ("' filename '").'])
	
	%the format is [x, y, width, height]                                   ��ʽ��[x��y����ȣ��߶�]
	try
		ground_truth = textscan(f, '%f,%f,%f,%f', 'ReturnOnError',false);  
	catch  %ok, try different format (no commas)                           ���Բ�ͬ�ĸ�ʽ���޶��ţ�
		frewind(f);
		ground_truth = textscan(f, '%f %f %f %f');  
	end
	ground_truth = cat(2, ground_truth{:});
	fclose(f);
	
	%set initial position and size                                         ���ó�ʼλ�úʹ�С
	target_sz = [ground_truth(1,4), ground_truth(1,3)];
	pos = [ground_truth(1,2), ground_truth(1,1)] + floor(target_sz/2);
	
	if size(ground_truth,1) == 1,
		%we have ground truth for the first frame only (initial position)  ����ֻ�е�һ֡��ground truth����ʼλ�ã�
		ground_truth = [];
	else
		%store positions instead of boxes                                  �洢λ�ö����ǿ�
		ground_truth = ground_truth(:,[2,1]) + ground_truth(:,[4,3]) / 2;
	end
	
	
	%from now on, work in the subfolder where all the images are           ��������������ͼ�����ڵ����ļ����й���
	video_path = [video_path 'img/'];
	
	%for these sequences, we must limit ourselves to a range of frames.    ������Щ���У����Ǳ��뽫�Լ�������һϵ��֡�С�
	%for all others, we just load all png/jpg files in the folder.         �����������������У�����ֻ������ļ����е�����png / jpg�ļ���
	frames = {'David', 300, 770;
			  'Football1', 1, 74;
			  'Freeman3', 1, 460;
			  'Freeman4', 1, 283};
	
	idx = find(strcmpi(video, frames(:,1)));
	
	if isempty(idx),
		%general case, just list all images                                һ������£�ֻ���г�����ͼ��
		img_files = dir([video_path '*.png']);
		if isempty(img_files),
			img_files = dir([video_path '*.jpg']);
			assert(~isempty(img_files), 'No image files to load.')
		end
		img_files = sort({img_files.name});
	else
		%list specified frames. try png first, then jpg.                   �г�ָ����֡�� �ȳ���PNG��Ȼ��JPG
		if exist(sprintf('%s%04i.png', video_path, frames{idx,2}), 'file'),
			img_files = num2str((frames{idx,2} : frames{idx,3})', '%04i.png');
			
		elseif exist(sprintf('%s%04i.jpg', video_path, frames{idx,2}), 'file'),
			img_files = num2str((frames{idx,2} : frames{idx,3})', '%04i.jpg');
			
		else
			error('No image files to load.')
		end
		
		img_files = cellstr(img_files);
	end
	
end

