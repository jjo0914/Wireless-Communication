%파리미터들
fc=28e9; % GHz
dlySpread=50e-9; % 가장짧은딜레이 ~ 가장 긴딜레이범위
chan = nrCDLChannel('DelayProfile','CDL-C',...
    'DelaySpread',dlySpread, 'CarrierFrequency', fc, ...
    'NormalizePathGains', true); % < 채널모델링 함수 = 클러스트러로만들겟다
                                 % 신호x를 chan(x)하면 채널적용해줌
                                % info(chan). 으로 채널 정보(gain, dly,위치)볼수있음

chaninfo=info(chan);% 클러스터가 총24개네

%% ----- 문제1: chaninfo에서 gain, angle of arrival azimuth랑, angle of arrival
% Elevation, angle of departure(반사라..) azimuth,elevation구하기-------------
gain=chaninfo.AveragePathGains; % dB단위
aoaAz=chaninfo.AnglesAoA; %Angles of azimuth
aoaEl=90-chaninfo.AnglesZoA; % zenith는 위에서아래각도
aodAz=chaninfo.AnglesAoD; % 
aodEl=90-chaninfo.AnglesZoD;
dly=chaninfo.PathDelays;
%% --문제2: 클러스트 개수는?--
npath=length(chaninfo.PathDelays); % 24개

%% --문제3: stem을 써서 gain과 delay를그리시오
stem(chaninfo.PathDelays*1e6,gain);
xlabel('delay(us)')
ylabel('Path gain(dB)')
title('1line=1cluster Channel')


%% ---문제4:  tx rx안테나를 patch안테나로 가장합니다 아래 코드를 그대로쓰시오--
% 안테나설계 공부?
vp = physconst('lightspeed');  % speed of light
lambda = vp/fc;   % wavelength

len = 0.49*lambda; % λ/2 공진이라는데
groundPlaneLen = lambda;
ant = patchMicrostrip(...
    'Length', len, 'Width', 1.5*len, ...
    'GroundPlaneLength', groundPlaneLen, ...
    'GroundPlaneWidth', groundPlaneLen, ...
    'Height', 0.01*lambda, ...
    'FeedOffset', [0.25*len 0]);

% xy평면을 y축으로 90도회전 = zy평면 x축방향안테나로 가정하는거야?
% 왜 x축방향으로 향하게하냐면 alignAxes가 r방향접선벡터를 반환하기때문에 이거를 x축으로 설정하려고
% 즉안테나를 강한경로로 축을 돌릴때 유용함
ant.Tilt = 90;
ant.TiltAxis = [0 1 0]; 


%% ----문제5: ElemWithAxes.m 코드의 alignAxes 채우기
% az,el받아서 r방향,az방향,el방향 단위벡터를 얻는다 왜? <몰라

%% ----문제6: ElemWithAxes.m 코드를 사용해서 gNB,UE의 fc,ant정보를 넘겨
% 똑같은안테나? 위치같은거는..?
elemUE = ElemWithAxes(fc, ant); % 단말 ElmWithAxes -> setupimpl실행
elemgNB = ElemWithAxes(fc, ant); % 기지국 ElmWithAxes -> setupimpl실행

%% --- 문제7: 간단한 가정: 가장강한경로=서로 align되어있을때
% 가장강한경로를 찾으라
[gainmax, im] = max(gain); % gain 0, 위치6
%% -- 문제8: elmUE랑 elemgNB의 alignAxes(azelaxes) 실행하기? 강한경로로
%elemUE.alignAxes
elemUE.alignAxes(aoaAz(im),aoaEl(im)) % > 가장강한 받는 경로의 r방향,az방향접선,el방향접선벡터구함(구가정)
elemgNB.alignAxes(aodAz(im),aodEl(im)) % > 가장강한 출발 경로의 r방향 ,az방향,el방향 접선벡터구함

%% --문제 9: ElemWithAxe 코드의 step클래스 채우기 (안테나를 돌려서 ,가장강한경로의 dir값추출)
%         ->실행
dirUE  = elemUE.step(aoaAz,aoaEl);  % 가장강한경로로 안테나축을 돌리고 나머지 경로의 directivity
 dirgNB  = elemgNB.step(aodAz,aodEl); % 가장강한경로로 안테나축을 돌리고 나머지 경로의 directivity

%% --문제 10: 안테나의 dir값을 알았으니깐 gain값 구하기?
%  txGain + pathGain+ rxGain
gainDir = dirgNB+gainmax+dirUE;

%% --문제 11: stem plot으로  gain이랑, gainDir그리기
%                                     방향성때문에 대부분감쇠되지만 몇몇은 증폭된다
hold on;
stem(chaninfo.PathDelays*1e6,gainDir);
legend('origianl Path gain','Path gain with directivty');
% 오리지널 path gain있는데 왜 안테나방향성을 추가한거지?
% 원래 채널모델링 gain은 방향성없는 등방성안테나라고 가정하는듯?.. 흠흠흠흠흠

%% --문제 12: ElemWithAxes class의 doppler 채우기
% ->도플러계산식 -v * fc * cos() / c  ( 코사인대신 벡터내전=행렬곱)
% 완

%% --문제 13: elemUE.set()으로 속도를 세팅하고 도플러계산 (도플러는 수신기준)
elemUE.set("vel",[0 27.7 0]); % y방향으로 100km/h 밟을때 
dop=elemUE.doppler(aoaAz,aoaEl);

% 이제 OFDM 신호를 만들어보자
fsamp=4*120e3*1024; % < 왜필요하지
nfft=1024;
nframe=512;

%% --문제14. ChanSounder.m 코드채우기 (nfft nframe받아서 신호만듬)
sounder=ChanSounder("nfft",nfft,'nframesTx',512);
x=sounder.getTx();

%% --문제15. SISOMPChan.m 의 steImpl() 채우기 (설정넘겨 최종신호 y만듬)
chan=SISOMPChan('fsamp',fsamp,'dly',dly,'dop',dop,'gain',gain);
y=chan(x); % 임의로만든랜ofdm신호에 멀티패스채널(딜레이+도플러쉬프트)을 적용 후 합

%% --문제16. 수신신호 y에 20 dB낮은 noise추가
P=mean(abs(y).^2); % 수신신호전력
wvar=db2pow(-20)*P; % 보다 20dB낮은 POWER
w=1/sqrt(2) .* (randn(length(y),1) + 1i*randn(length(y),1)); % 평균전력1
w=sqrt(wvar)*w; %
ynoisy=y+w;

%% -문제17. ChanSounder의 getChanEst채우기 (수신신호의 채널추정)
% 채널추정해주고
[hest, hestFd] = sounder.getChanEst(ynoisy);

% hestFd를 db스케일로플롯팅 프레임이여러개니깐 프레임별로플로팃하면되나%
% 가로축 시간 세로축 열을 image형태로플롯팅
HdB=mag2db(abs(hestFd)); % 행 nfft 주파수 열 nframe시간
df=fsamp/nfft; % 서브캐리어간격
f=(0:nfft-1)*df/1e6; % mHz단위
Tframe=nfft/fsamp; % 1프레임시간 1frame=
t=(0:nframe-1) * Tframe*1e3;% ms
figure;
imagesc(t, f, HdB);
axis xy;                                 % y축 방향 위로 증가
xlabel('Time (ms)');
ylabel('Frequency (MHz)');
colorbar;
title('Estimated channel |H(f,t)| in dB');

%% --문제18: 프레임별로 hest를 추정했는데 1프레임만 선택해서 시간축 으로출력
figure;
t=(0:(nfft-1))./fsamp;
plot(t*1e6,mag2db(abs(hest(:,1)))) % 진폭dB인가? pow dB인지?
title('Channel Estimation 1frame')
xlim([0 0.5]);
xlabel('Time (us)'); % peak 위치가  tap 위치 시간이랑비슷한지? < 어 시간이 꽤비슷한데?

%% --문제19: h(nsample,nframe)추정된 채널로 딜레이 찾기 (피크위치)
% h의크기 구하고 -> 오른쪽으로 더해서 ->  피크가 진짜채널의 delay 오케이

[~,im]=max(sum(abs(hest).^2,2)); % im:gain이 가장클때 delay

% im일때의 채널 추정 real imag 값을 플로팅해보면 페이딩을 확인할수있다(출렁출렁)
% 크기는 | | 이니깐 도플러있어도 변함이없는데 real iamg는 cos sin항땜에생김
h_strong = hest(im,:);        % 가장 강한 delay 의 채널값을확인해보면
% 프레임이 흐를수록(시간이지날수록) 출렁출렁한데 도플러가없다면 평평하대
figure;
t = (0:nframe-1) * Tframe;
plot(t, real(h_strong), '-o'); hold on;
plot(t, imag(h_strong), '-x');
%plot(t,abs(hest(im,:)).^2); % flat하지않은데? 다중경로+잡음+추정오차땜에그렇다..
xlabel('Time (s)');
ylabel('Channel gain');
legend('Real','Imag');
title('Time variation of strongest tap h(im,:)');
grid on;

%% ----------- SDR부분 ----------------
loopback = true;  
runTx = true;
runRx = true;
fc = 2.422e9;  % WIFI Channel 3 의중심주파수
fsamp = 2*30.72e6; % 샘플링 60mHz ?!
nfft = 1024;    % n
nframe = 32;    % n
clear sdrtx sdrrx

nsampsFrame = nfft*nframe;
[sdrtx, sdrrx] = plutoCreateTxRx(createTx = runTx, createRx = runRx, loopback = loopback, ...
    nsampsFrameTx = nsampsFrame, nsampsFrameRx = nsampsFrame, sampleRate = fsamp, centerFrequency=fc);

% 랜덤 OFDM X신호만들기
sounder=ChanSounder("nfft",nfft,'nframesTx',nframe);
x=sounder.getTx();  % 1024

if runTx
    % Release any previous transmission and continuously send x.
    sdrtx.release();
    sdrtx.transmitRepeat(x);    
end
r=sdrrx.capture( nframe*nfft);

fullScale = 2^11;
r = single(r)/fullScale;
[hest,hestFd] = sounder.getChanEst(r);
% 채널추정 1개만 플롯팅
% 추정채널의 first 프레임만 보면 peak가보이지만 tx와 rx사이에 딜레이를 확인할수잇다
hdb=mag2db(abs(hest));
t=(0:(nfft-1))./fsamp;
figure;
plot(t*1e6,hdb(:,1))
xlabel('Time (us)');
ylabel('Channel gain(dB)');
title('Channel estimation h(:,1) peak=delay');
xlim([0 0.5])
grid on;
% gain이가장큰 delay추정
[~,im]=max(sum(abs(hest).^2,2)); % im:gain이 가장클때 delay
h_strong = hest(im,:);        % 가장 강한 delay 의 채널값을확인해보면
% 프레임이 흐를수록(시간이지날수록) 출렁출렁한데 도플러가없다면 평평하대
figure;
t = (0:nframe-1) * Tframe;
plot(t, real(h_strong), '-o'); hold on;
plot(t, imag(h_strong), '-x');
%plot(t,abs(hest(im,:)).^2); % flat하지않은데? 다중경로+잡음+추정오차땜에그렇다..
xlabel('Time (s)');
ylabel('Channel gain');
legend('Real','Imag');
title('Time variation of strongest tap h(im,:)');
grid on;



