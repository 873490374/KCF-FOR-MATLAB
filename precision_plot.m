function precisions = precision_plot(positions, ground_truth, title, show)
%PRECISION_PLOT
%   Calculates precision for a series of distance thresholds (percentage of����һϵ�о�����ֵ�ľ���
%   frames where the distance to the ground truth is within the threshold).����ground truth�ľ�������ֵ�ڵ�֡�İٷֱȣ���
%   The results are shown in a new figure if SHOW is true.                 ���SHOWΪ�棬���������ͼ����ʾ��
%
%   Accepts positions and ground truth as Nx2 matrices (for N frames), and ����λ�ú�ground truth��ΪN��2���󣨶���N��֡����һ�������ַ�����
%   a title string.
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/

	
	max_threshold = 50;  %used for graphs in the paper                     ���������е�ͼ��
	
	
	precisions = zeros(max_threshold, 1);
	
	if size(positions,1) ~= size(ground_truth,1),
% 		fprintf('%12s - Number of ground truth frames does not match number of tracked frames.\n', title)
		
		%just ignore any extra frames, in either results orground truth    ֻҪ�����κζ����֡�������ǽ������ground truth
		n = min(size(positions,1), size(ground_truth,1));
		positions(n+1:end,:) = [];
		ground_truth(n+1:end,:) = [];
	end
	
	%calculate distances to ground truth over all frames                   ������֡�ϼ������ground truth�ľ���
	distances = sqrt((positions(:,1) - ground_truth(:,1)).^2 + ...
				 	 (positions(:,2) - ground_truth(:,2)).^2);
	distances(isnan(distances)) = [];

	%compute precisions                                                    ���㾫��
	for p = 1:max_threshold,
		precisions(p) = nnz(distances <= p) / numel(distances);
	end
	
	%plot the precisions                                                   ���ƾ���ͼ
	if show == 1,
		figure('Number','off', 'Name',['Precisions - ' title])
		plot(precisions, 'k-', 'LineWidth',2)
		xlabel('Threshold'), ylabel('Precision')
	end
	
end

