% Lab2.m

% 시뮬레이션 이미지 로드
A = imread('map.png'); % 시뮬이미지
imshow(A, 'InitialMagnification', 40); % 'InitialMagnification':Zoom level
% 레이트레이싱 결과
load pathData; %-> rxpos ,txpos pathTable

%문제1: tx와 rx의 갯수는?
ntx=size(txpos,1); % 송신기20개
nrx=size(rxpos,1); % 수신기100개
%문제2: tx와 rx의 위치를 플롯팅
figure;
plot(txpos(:,1),txpos(:,2),'o');
hold on
plot(rxpos(:,1),rxpos(:,2),'s');
legend('송신기','수신기')

%문제3: head 명령어를사용하여  몇 행정도출력
head(pathTable,5);

%문제4: 루프문을사용하여 각경로가 존재하면 총rx_power랑 최소 delay를구해라
totRx=zeros(ntx,nrx);
linkstate=zeros(ntx,nrx);
minDly=NaN(ntx,nrx);
%문제9를위해 미리좀계산
dist1=sqrt((txpos(:,1)-rxpos(:,1)').^2 + (txpos(:,2)-rxpos(:,2)').^2 + (txpos(:,3)-rxpos(:,3)').^2 );
for n=1:height(pathTable)
    i=pathTable(n,1).Variables;
    j=pathTable(n,2).Variables;
    if totRx(i,j)==0 % 첫경로
        % 지연시간비교
        ref_t=dist1(i,j)/299792458; % los시간
        toa=pathTable(n,5).Variables;%지연시간
        
        if (1.05> toa/ref_t) && toa/ref_t > 0.95 % 5퍼차이면 LOS <기준에따라
        linkstate(i,j)=pathTable(n,3).Variables;% =LOS
        end

     end
    totRx(i,j)=totRx(i,j)+db2pow(pathTable(n,3).Variables);
    minDly(i,j)=min(pathTable(n,5).Variables,minDly(i,j));
end
totRx(ismember(totRx,0))=NaN;
%문제5:총보낸파워가36dBm일때 path loss는?
pathloss=36-pow2db(totRx);

%문제6: 루프문없이 tx rx거리를계산..  전치를사용?->배열 하나씩 경우의수로다빼줌 
% 전치를 어디로 사용하냐에따라 배열이다름
% [1 2]-[1 2 3]'= 3*2 배열 [1 2]'-[1 2 3]=2*3배열
dist=sqrt((txpos(:,1)-rxpos(:,1)').^2 + (txpos(:,2)-rxpos(:,2)').^2 + (txpos(:,3)-rxpos(:,3)').^2 );
dist(isnan(totRx))=NaN;
%문제7: fspl 사용 free space path loss게산
c=physconst('LightSpeed');
dmin = 10; % 10~ 500m
dmax = 500;
fc = 1.9e9;     % Carrier frequency
fPathloss=fspl(10:500,c/fc);

%문제8: Scatterplot 거리vsPathloss & Freespace Pathloss 
figure;
scatter(dist(:),pathloss(:)); % scatter: scatterplot: I/Q용
hold on
scatter(dmin:dmax,fPathloss);
xlabel('distance(m)')
ylabel('Path loss(dB)')
legend('시뮬','free-space path loss')

%문제9: 수신기&송신기 링크를 직접파 혹은 반사파 혹은 링크없음으로 나타내기
%어떻게알아? 1.맨처음 신호가 los일 확률이높다. 2.전파지연시간을 거리/빛속도와비교 5퍼차이면los가저
LOS_idx=~ismember(linkstate,0);
losdist=dist(LOS_idx);
OUT_idx=isnan(totRx);
NLOS_idx= ~(LOS_idx+OUT_idx);
nlosdist=dist(NLOS_idx);
%문제10: LOS,NLOS,OUT총비율출력 nrx*ntx 안해

%문제11: LOS,NLOS의 dist vs pathloss출력
%       x축=10log10(distance)
figure;
scatter(10*log10(losdist(:)),pathloss(LOS_idx))
hold on
scatter(10*log10(nlosdist(:)),pathloss(NLOS_idx))
hold on
scatter(10*log10(dmin:dmax),fPathloss);
xlabel('10log10(distance(m))')
ylabel('Path loss(dB)')
legend('LOS포함 경로','NLOS 경로','free space Path loss')

%문제12: LOS,NLOS 결과 피팅하기위해 a,b,xi찾기 (PYTHON sklearn tool이더좋다)
%  a + b*10*log10(dist) + xi, xi~N(0,std^2) <모델
% a,b는 명령어 fitlm을 사용하세요 <machine learing에서봄
% fitlm = a+b x1 찾아줌

linearfit1=fitlm(10*log10(losdist(:)),pathloss(LOS_idx)); % 첫째열이 예측변수 마지막열 반응
                                                  % linear모델<기본
fprintf("LOS : %f + %f 10log10(dist), 표준편차: %f \n",linearfit1.Coefficients.Estimate(1),linearfit1.Coefficients.Estimate(2),linearfit1.RMSE);
linearfit2=fitlm(10*log10(nlosdist(:)),pathloss(NLOS_idx));
fprintf("NLOS : %f + %f 10log10(dist) 표준편차: %f \n",linearfit2.Coefficients.Estimate(1),linearfit2.Coefficients.Estimate(2),linearfit2.RMSE);
h1=plot(linearfit1);
h1(1).Visible='off';
h1(1).DisplayName='';
h1(3).Visible='off';
h1(3).DisplayName='';
h1(2).DisplayName='LOS fit curve'
hold on
h2=plot(linearfit2);
h2(1).Visible='off';
h2(1).DisplayName='';
h2(3).Visible='off';
h2(3).DisplayName='';
h2(2).DisplayName='NLOS fit curve'
xlabel('10log10(distance(m))')
ylabel('Path loss(dB)')
title('')

%문제13: 링크상태를 거리에따라 비율로 나타내기 멀수록 LOS감소 OUT증가
% histocounts랑 bar명령어사용
% 0~500 / 0~50 / 51~100
figure;
nbins = 10;
binwid = 50;
binlim = [0,nbins*binwid];
bincenter = ((0:nbins-1)' + 0.5)*binwid;

N=histcounts(dist1,'BinWidth',binwid,'BinLimits',binlim);
LOS_N=histcounts(dist(LOS_idx),'BinWidth',binwid,'BinLimits',binlim);
NLOS_N=histcounts(dist(NLOS_idx),'BinWidth',binwid,'BinLimits',binlim);
OUT_N=histcounts(dist1(OUT_idx),'BinWidth',binwid,'BinLimits',binlim);

% bar stack 사용법
bar(bincenter,[LOS_N./N;NLOS_N./N;OUT_N./N;],'stacked')
legend('LOS','NLOS','OUT')
xlabel('distance(m)')
ylabel('fraction')
ylim([-0.001 1.1])

%문제14: 거리에따라 링크상태 확률을 추정을 mnrfit로 학습하라
% multi-class logistic model 식:log(P(NLOS)/P(LOS))= -B1(NLOS)dist-B2(NLOS)
% 확률이 거리에따라감소하는식이래
link=zeros(ntx,nrx);
link(NLOS_idx)=1;
link(OUT_idx)=2;
link=link+1; % LOS:1 NLOS:2 OUT:3
% mnrfit x -> fitmnr 사용법
MNR=fitmnr(dist1(:),link(:)); % 예측,응답 B가계수?
[p,prob,~,~]=predict(MNR,bincenter); % 값,확률,신뢰구간하향치?,상향치
                                       % 입력을열로받네
figure;
bar(bincenter,prob,'stacked');
legend('LOS예측','NLOS예측','OUT예측')
xlabel('distance(m)')
ylabel('fraction')
ylim([-0.001 1.1])
title('fitmnr 예측')