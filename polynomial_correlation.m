function kf = polynomial_correlation(xf, yf, a, b)
%POLYNOMIAL_CORRELATION Polynomial Kernel at all shifts, i.e. kernel correlation.����ʽ�ں���������λ�����ں���ء�
%   Evaluates a polynomial kernel with constant A and exponent B, for all  ��������ͼ��XF��YF֮����������λ�ƣ�
%   relative shifts between input images XF and YF, which must both be MxN.����һ������ΪA��ָ��ΪB�Ķ���ʽ�ˣ����Ǳ��붼��M��N��
%   They must also be periodic (ie., pre-processed with a cosine window).  ����Ҳ�����������Եģ����������Ҵ�Ԥ������
%   The result is an MxN map of responses.                                 �����һ��MxN��Ӧͼ��
%
%   Inputs and output are all in the Fourier domain.
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/
	
	%cross-correlation term in Fourier domain                              ����Ҷ���еĻ������
	xyf = xf .* conj(yf);
	xy = sum(real(ifft2(xyf)), 3);  %to spatial domain                     ת���ռ���
	
	%calculate polynomial response for all positions, then go back to the  ��������λ�õĶ���ʽ��Ӧ��Ȼ�󷵻ص�����Ҷ��
	%Fourier domain
	kf = fft2((xy / numel(xf) + a) .^ b);

end

