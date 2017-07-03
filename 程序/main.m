%1.2车牌图像预处理
% 1.灰度化
I=imread('test.jpg'); %输入原始图像
figure(1)
subplot(2,1,1);
imshow(I);
title('原始图像');
I_gray=rgb2gray(I);
subplot(2,1,2);
imshow(I_gray);
title('灰度图像');

%2.图像去噪
I_med=medfilt2(I_gray,[3,3]); %对灰度图像进行中值滤波，消除图像上的杂质干扰
imshow(I_med);
title('中值滤波后的图像');

%3.灰度变换
I_imad=imadjust(I_med);
imshow(I_imad);
title('灰度变换后的图像');

%4.边缘检测
I_edge=edge(I_imad,'Roberts'); %改为Roberts
imshow(I_edge);
title('边缘检测后的图像');

%5.形态学处理
se=[1;1;1];
I_erode=imerode(I_edge,se); %图像腐蚀运算
se=strel('rectangle',[25,25]);
I_close=imclose(I_erode,se); %图像闭运算，填充图像
I_final=bwareaopen(I_close,3000); %去除聚团灰度值小于2000的部分
imshow(I_final);
title('形态滤波后的图像');

%1.3车牌定位
[y,x,z]=size(I_final);		%将I5的行列像素点总和分别放入变量y,x中
I6=double(I_final);
Y1=zeros(y,1);			%定义一个y行1列的矩阵
for i=1:y;
for j=1:x;
		if(I6(i,j,1) ==1)
			Y1(i,1)=Y1(i,1)+1;
		end
	end
end
[temp MaxY]=max(Y1);	%计算行列像素值总和。并将最大的列所在的位置存放到MaxY中
PY1=MaxY;				%先将最大的像素总和位置赋值给PY1
while((Y1(PY1,1) >=50) && (PY1>1))
		PY1=PY1-1;
	end		%while循环得到和最大像素点连通区域的上边界
	PY2=MaxY;	%先将最大的像素总和位置赋值给PY2
	while((Y1(PY2,1) >=50) && (PY2<y))
		PY2=PY2+1;
	end			%while循环得到的和最大像素点连通的区域的下边界
	%%%%%%%%%%%%%%%求的车牌的列起始位置和终止位置%%%%%%%%%%%
	X1=zeros(1,x);	%定义一个1行x列的矩阵
	for j=1:x
		for i=PY1:PY2
			if(I6(i,j,1)==1)
				X1(1,j)=X1(1,j)+1;
			end
		end
	end  %通过循环，求得到像素值总和最大 的位置
	PX1=1;	%先将PX1赋值为1
	while((X1(1,PX1)<3) && (PX1<x))
		PX1=PX1+1;
	end		%用while循环得到左边界
	PX2=x;	%将PX2赋值为最大值x
	while((X1(1,PX2)<3) && (PX2>PX1))
		PX2=PX2-1;
	end  %用while循环得到右边界
	PX1=PX1-1;
	PX2=PX2+1;
	PY1=PY1+15/915*(PY2-PY1);
	PX1=PX1+15/640*(PX2-PX1);
	PX2=PX2-15/940*(PX2-PX1);

%根据经验值对车牌图像的位置进行微调
dw=I(PY1:PY2,PX1:PX2,:);
imshow(dw); %剪切并输出定位后的车牌

% t=toc; 
figure(7),subplot(1,2,2),imshow(dw),title('定位剪切后的彩色车牌图像')
imwrite(dw,'dw.jpg');
[filename,filepath]=uigetfile('dw.jpg','输入一个定位裁剪后的车牌图像');
jpg=strcat(filepath,filename);
a=imread('dw.jpg');
b=rgb2gray(a);
imwrite(b,'1.车牌灰度图像.jpg');
figure(8);subplot(3,2,1),imshow(b),title('1.车牌灰度图像')
g_max=double(max(max(b)));
g_min=double(min(min(b)));
T=round(g_max-(g_max-g_min)/3); % T 为二值化的阈值
[m,n]=size(b);
d=(double(b)>=T);  % d:二值图像
imwrite(d,'2.车牌二值图像.jpg');
figure(8);subplot(3,2,2),imshow(d),title('2.车牌二值图像')
figure(8),subplot(3,2,3),imshow(d),title('3.均值滤波前')

% 滤波
h=fspecial('average',3);
d=im2bw(round(filter2(h,d)));
imwrite(d,'4.均值滤波后.jpg');
figure(8),subplot(3,2,4),imshow(d),title('4.均值滤波后')

% 某些图像进行操作
% 膨胀或腐蚀
% se=strel('square',3);  % 使用一个3X3的正方形结果元素对象对创建的图像进行膨胀
% 'line'/'diamond'/'ball'...
se=eye(2); % eye(n) returns the n-by-n identity matrix 单位矩阵
[m,n]=size(d);
if bwarea(d)/m/n>=0.365
    d=imerode(d,se);
elseif bwarea(d)/m/n<=0.235
    d=imdilate(d,se);
end
imwrite(d,'5.膨胀或腐蚀处理后.jpg');
figure(8),subplot(3,2,5),imshow(d),title('5.膨胀或腐蚀处理后')

% 寻找连续有文字的块，若长度大于某阈值，则认为该块有两个字符组成，需要分割
d=incise(d);
[m,n]=size(d);
figure,subplot(2,1,1),imshow(d),title(n)
k1=1;k2=1;s=sum(d);j=1;
while j~=n
    while s(j)==0
        j=j+1;
    end
    k1=j;
    while s(j)~=0 && j<=n-1
        j=j+1;
    end
    k2=j-1;
    if k2-k1>=round(n/6.5)
        [val,num]=min(sum(d(:,[k1+5:k2-5])));
        d(:,k1+num+5)=0;  % 分割
    end
end
% 再切割
d=incise(d);
% 切割出 7 个字符
y1=10;y2=0.25;flag=0;word1=[];
while flag==0
    [m,n]=size(d);
    left=1;wide=0;
    while sum(d(:,wide+1))~=0
        wide=wide+1;
    end
    if wide<y1   % 认为是左侧干扰
        d(:,[1:wide])=0;
        d=incise(d);
    else
        temp=incise(imcrop(d,[1 1 wide m]));
        [m,n]=size(temp);
        all=sum(sum(temp));
        two_thirds=sum(sum(temp([round(m/3):2*round(m/3)],:)));
        if two_thirds/all>y2
            flag=1;word1=temp;   % WORD 1
        end
        d(:,[1:wide])=0;d=incise(d);
    end
end
% 分割出第二个字符
[word2,d]=getword(d);
% 分割出第三个字符
[word3,d]=getword(d);
% 分割出第四个字符
[word4,d]=getword(d);
% 分割出第五个字符
[word5,d]=getword(d);
% 分割出第六个字符
[word6,d]=getword(d);
% 分割出第七个字符
[word7,d]=getword(d);

subplot(5,7,1),imshow(word1),title('1');
subplot(5,7,2),imshow(word2),title('2');
subplot(5,7,3),imshow(word3),title('3');
subplot(5,7,4),imshow(word4),title('4');
subplot(5,7,5),imshow(word5),title('5');
subplot(5,7,6),imshow(word6),title('6');
subplot(5,7,7),imshow(word7),title('7');
[m,n]=size(word1);

% 商用系统程序中归一化大小为 40*20,此处演示
word1=imresize(word1,[40 20]);
word2=imresize(word2,[40 20]);
word3=imresize(word3,[40 20]);
word4=imresize(word4,[40 20]);
word5=imresize(word5,[40 20]);
word6=imresize(word6,[40 20]);
word7=imresize(word7,[40 20]);

subplot(5,7,15),imshow(word1),title('1');
subplot(5,7,16),imshow(word2),title('2');
subplot(5,7,17),imshow(word3),title('3');
subplot(5,7,18),imshow(word4),title('4');
subplot(5,7,19),imshow(word5),title('5');
subplot(5,7,20),imshow(word6),title('6');
subplot(5,7,21),imshow(word7),title('7');

imwrite(word1,'1.jpg');
imwrite(word2,'2.jpg');
imwrite(word3,'3.jpg');
imwrite(word4,'4.jpg');
imwrite(word5,'5.jpg');
imwrite(word6,'6.jpg');
imwrite(word7,'7.jpg');
liccode=char(['琼苏藏川鄂甘赣贵桂黑沪吉冀津晋京辽鲁蒙闽宁青陕皖湘新渝豫粤云浙' 'A':'Z' '0':'9']);
%liccode=char(['0':'9' 'A':'Z' '苏豫陕鲁']);  %建立自动识别字符代码表  
%liccode=char(['0':'9'  'A':'Z' '苏藏川鄂甘赣贵桂黑沪吉冀津晋京辽鲁蒙闽宁青琼陕皖湘新渝豫粤云浙']);

SubBw2=zeros(40,20);
l=1;
for I=1:7
      ii=int2str(I);
     t=imread([ii,'.jpg']);
      SegBw2=imresize(t,[40 20],'nearest');
      SegBw2=im2bw(SegBw2);
        if l==1                 %第一位汉字识别
            kmin=1;
            kmax=31;
        elseif l==2             %第二位 A~Z 字母识别
            kmin=32;
            kmax=57;
        else l >= 3               %第三位以后是字母或数字识别
            kmin=58;
            kmax=67;
        
        end
        
        for k2=kmin:kmax
            fname=strcat('字符模板\',liccode(k2),'.jpg');
            SamBw2 = imread(fname);
            SamBw2=im2bw(SamBw2);
            for  i=1:40
                for j=1:20
                    SubBw2(i,j)=SegBw2(i,j)-SamBw2(i,j);
                end
            end
           % 以上相当于两幅图相减得到第三幅图
            Dmax=0;
            for k1=1:40
                for l1=1:20
                    if  ( SubBw2(k1,l1) > 0 || SubBw2(k1,l1) <0 )
                        Dmax=Dmax+1;
                    end
                end
            end
            Error(k2)=Dmax;
        end
        Error1=Error(kmin:kmax);
        %Error1=Error(1:68);
        MinError=min(Error1);
        findc=find(Error1==MinError);
        Code(l*2-1)=liccode(findc(1)+kmin-1);
        Code(l*2)=' ';
        l=l+1;
end
figure(13),
imshow(dw),
title (['车牌号码为:',Code]);
