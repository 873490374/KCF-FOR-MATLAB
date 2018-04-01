function kf = linear_correlation(xf, yf)
%LINEAR_CORRELATION Linear Kernel at all shifts, i.e. correlation.         �����ں�������λ�ƣ�����ء�
%   Computes the dot-product for all relative shifts between input images  ��������ͼ��X��Y֮����������ƫ�Ƶĵ����
%   X and Y, which must both be MxN. They must also be periodic (ie.,      ����ͼ��Ĵ�С���Ǳ��붼��MxN��
%   pre-processed with a cosine window). The result is an MxN map of       ����Ҳ�����������Եģ����������Ҵ�Ԥ������
%   responses.                                                             �����һ��MxN��Ӧͼ��
%
%   Inputs and output are all in the Fourier domain.                       �����������ڸ���Ҷ��
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/
	
	%cross-correlation term in Fourier domain                              ����Ҷ���еĻ������
	kf = sum(xf .* conj(yf), 3) / numel(xf);                               %conj�������Ĺ���

end

