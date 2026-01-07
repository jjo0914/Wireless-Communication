% 5g toolbox로 다운링크  송수신체인만들기
% 실제론엄청복잡한데 툴박스가해준다
% 일단 해보기
clear all;
% --5G 기본--
% 5G는 커버하는 대역폭이너무다양해서 슬롯이라는개념이있다.
% 1프레임 10ms ,1 서브프레임 1ms <<고정
% 그안에 1슬롯=1ms , 2슬롯=1ms  이렇게나누었고 슬롯갯수가많을수록
% 서브캐리어간격이큼(심볼 시간이 빨라짐. t=1/f)
% 표에의해 u가 정해지면 -> 서브캐리어 간격정해짐 ,1 리소스블록 =12서브캐리어갯수
% 1ofdm 심볼은 = 리소스블록갯수 *12서브캐리어 , 숫자가결정됨 
% 그리고 1슬롯은 여러개의 OFDM심볼을 포함함 (보통 1slot=14ofdm심볼)

%설정
fc = 28e9;                % Carrier frequency
SubcarrierSpacing = 120;  % SCS in kHZ
NRB = 66;  % number of resource blocks
nscPerRB = 12;  % number of sub-carriers per RB
% -> u=3 대역폭100MHZ 설정이래
%% -------------문제1  : 자원대역폭을 계산하시오
bwMHz=nscPerRB*NRB*SubcarrierSpacing/1e3; % 이건 자원대역폭 Mhz
% --------------------------------------
fprintf("자원 대역폭(RB갯수 * 12서브캐리어 * Δf) : %.2f MHz \n",bwMHz);

%% ----------- 문제 2 : nrCarrierConfig함수에 입력으로 서브캐리어간격(kHz)랑 nSizeGrid(RB)갯수를 넣어라
% nrCarrierConfig : 5g 함수들이 받을수있는 특별한함수로 OFDM 캐리어 에대한 정보를 설정할수있음
carrierConfig = nrCarrierConfig('SubcarrierSpacing',SubcarrierSpacing,'NSizeGrid',NRB); % 단위 kHz네
%-----------------------------------------------------------------------

waveformConfig= nrOFDMInfo(carrierConfig); % 캐리어설정으로 OFDM 세부수치를 저장
                                           %(샘플링 주파수 +nfft+cp길이 등..?)
                                           % 1ms 정보 딱주는듯
fprintf("필요 샘플링 rate : %.2f Mhz  OFDM심볼갯수(1서브프레임당) : %.2f 개 \n",waveformConfig.SampleRate/1e6,waveformConfig.SlotsPerFrame*waveformConfig.SymbolsPerSlot/10)

% 시간영역으로 안바꾸고 주파수영역에서만 시뮬레이션하겠다.(송수신 필터링절차, 채널추정,등화과정생략)
% 어찌됫는 채널 파라미터는?
gain = [0,-3]';      % path gain in dB
dly = [0, 200e-9]';  % path delays in seconds
aoaAz = [0, 180]';  % angles of arrival
aoaEl = [0, 20]'; % 각도가 나온다? -> 도플러주파수 계산할떄필요..
Etx = 1;        % 보낼때 심볼에너지 1

% 수신기속도..
rxVel = [30,0,0]'; % vx + vy +vz (m/s)
EsN0Avg = 20;   % 수신 기준노이즈래 이거 채널평균1로맞춰야한다는데
                % Average SNR Es/No... dB (시뮬은 코딩없이..)

%% -------문제 3 : 첨부한 FDChan. m 의 obj.gainComplex(각경로의 채널gain계산) 를채워라 
% 문제 3-1 : 도플러주파수도 계산 ->출력 (fdchan.fd)
% 문제 3-2 : 1서브프레임내에  ofdm 심볼시간은? (ofdminfo에 정보다있음)         
% 식참조(Unit3.  44p. & 39p)
fdchan = FDChan(carrierConfig, 'gain', gain, 'dly', dly, 'aoaAz', aoaAz, 'aoaEl', aoaEl, ...
    'rxVel', rxVel, 'Etx', Etx, 'EsN0Avg', EsN0Avg, 'fc', fc);
% ----------------------------------------------------------------------------

%% -------문제 4 :  FDChan.stepImpl 채우기
% txGrid(주파수)에 채널상태 적용해서 rxGrid(주파수)만들기
%  아이거 식 H에 txGrid곱하고 noise적용..
NumLayers = 1;
txGrid = nrResourceGrid(carrierConfig, NumLayers);
txGrid(:) = 1;
[rxGrid, chanGrid, noiseVar]=fdchan.step(txGrid,1,1); % < 1슬롯 rxGrid % chanGrid 반환

%%------문제5 : rxGrid의 순간 SNR(dB)계산하고 imagesc 함수사용
% 채널의 fast fading을 확인 : 주파수축 &시간축 에사 막변함
% slow fading :  1슬롯마다 전력을 요약 시간축으로 그리고 평평하면 slow fading

SNR=pow2db((abs(chanGrid).^2) ./ noiseVar) ; % SNR = Es/No ( power)
imagesc(SNR); % 1슬롯 : fast fading 확인
axis xy; % y축을 행렬식이아니라 y좌표처럼밑에가 0으로 바꿈(행렬은 위에가0)
xlabel('OFDM symbol index');
ylabel('Subcarrier index');
colorbar;
title('Instantaneous SNR (dB)');

%% ---문제추가 여기 채널확인점
% 슬롯전송많이  할수록 채널상태 변하는거 확인함 ㅇㅇ
%Suppose we transmit on slotNum=0 for sfNum=i for i=0,...,ntx for ntx=100.
% figure;
% h=imagesc(SNR);
% axis xy;
% xlabel('OFDM symbol index');
% ylabel('Subcarrier index');
% colorbar;
% title('Instantaneous SNR (dB)');
% 
% for i=1:100 % 일단8슬롯까지만=1서브프레임
%     sfNum = floor((i-1)/8) + 1; % 8슬롯1서브프레임 9슬롯부터 2서브
%    [rxGrid, chanGrid, noiseVar]=fdchan.step(txGrid,sfNum,i); % 채널적용~
%    SNR=pow2db((abs(chanGrid).^2) ./ noiseVar) ;
%    h.CData=SNR;
%    drawnow
% end

%이제 PDSCH (다운링크 데이터부분) 송신기 단순하게만들기 mcs=13 설정 테이블참 고 
% (pdcch는 안하나봄)
mcsInd = 13;
Modulation = '16QAM' %테이블참조
targetCodeRate = 490/1024; %테이블참조
% nrPDSCHConfig 함수로 pdsch설정만들기 
% 인덱스는 0부터
pdschConfig = nrPDSCHConfig(...
    'Modulation', Modulation, ...
    'PRBSet', (0:NRB-1), ... %PRB는 0부터 시작하는데 첫번째 RB 부터 ~까지 pdsch로쓸지
    'SymbolAllocation', [1, waveformConfig.SymbolsPerSlot-1], ...% 어느심볼을 pdsch로쓸지 첫심볼만비워두네
    'EnablePTRS', 1,... %  PTRS는 위상추적용 파일럿신호를 넣을것인가?
    'PTRS', nrPDSCHPTRSConfig()); %   % PTRS그냥기본값인데 객체로들어간데 무슨설정이있나봐
% 5G NR표준 TX데이터를 실제로구현하려면 너무방대하고 복잡하다
% LDPC 코딩 -> 스크램블링(비트 값바꾸기..) -> QAM-> OFDM그리드에 배치
% 여기서는 toolbox랑 제공하는 코드를 그냥써라.
tx = NRgNBTxFD(carrierConfig, pdschConfig, 'targetCodeRate', targetCodeRate);
txGrid = tx.step();% 비트는 17424개 랜덤비트..


%% ----문제 6: 제공한 함수로 만든 txGrid(PDSCH)를 imagesc함수로 그리고 zero값들을 표시하라
mask = (txGrid ~= 0); % 빈곳은 0 
figure;
imagesc(mask); 
axis xy;
colormap(gray);
caxis([0 1]);          % 0과 1에 맞춰 강제로 스케일 고정
colorbar;
xlabel('OFDM symbol'); ylabel('Subcarrier');
title('txGrid (zero=0, non-zero=1)');
% 첫번째 심볼 값들: 의도적으로 비움 , 3번째 심볼 값들 :복조 참조용 DM-RS 신호 자리 , 수평 zero값들 : 위상이동 추적용 PT-RS신호 자리

% nrPDSCHIndices: data pdsch 인덱스를 선형으로 반환함
[pdschInd,pdschInfo] = nrPDSCHIndices(carrierConfig, pdschConfig);

%% --- 문제 7 :PDSCH DATA index (sym)만 플롯팅 하시오 예상 16qam 
pdschSym=txGrid(pdschInd);
figure;
scatter(real(pdschSym),imag(pdschSym)) % 2차행렬에 선형인덱스를넣어도 되넴
%% ---문제 8 : 만들어진 비트의 갯수랑 spectral efficency(M*codeRate) 계산
nbits=length(tx.txBits{1}); % 정보비트
length(pdschSym); % 실제심볼 * M= 코딩비트
speffi=(4*nbits) / (length(pdschSym)*4); % 정보비트*M/코딩비트=spectral efficeny
                                        % table값 1.91 유사함 ㄷ
% 이제 수신파트..
% 채널추정 -> 디코딩까지 전부 함수로..
%% ---문제 9 : 제공한 NRUERxFD함수의 TODO: 부분을채우기 (그냥 함수()채우기 이정도)
rx = NRUERxFD(carrierConfig, pdschConfig, 'targetCodeRate', targetCodeRate);


%% --문제 10 : 1슬롯 txGrid를 만들고 (이미함) 채널적용하고  rx.step(rx,chan,noiseVar)하고
% rx.심볼 찍어보기
fdchan = FDChan(carrierConfig, 'gain', gain, 'dly', dly, 'aoaAz', aoaAz, 'aoaEl', aoaEl, ...
    'rxVel', rxVel, 'Etx', Etx, 'EsN0Avg', 20, 'fc', fc); % EsN0=20dB로바꾸래
[rxGrid, chanGrid, noiseVar]=fdchan.step(txGrid,1,1);
rx.step(rxGrid,chanGrid,noiseVar);
% rx.pdschEq <심볼 ,rx.rxBits < 비트(별수식다씀)
figure;
scatter(real(rx.pdschEq),imag(rx.pdschEq))
hold on;
scatter(real(pdschSym),imag(pdschSym),MarkerEdgeColor='r',MarkerFaceColor='r')
legend('Equalized  RX Symbol','Tx Symobl')

% 문제11: tx grid 500번만들고 rx.step해서 비트추정한다음 오류가50번나면종료
% 8dB로 갈수록 에러율이 0으로감  1000번하면 가끔씩실패함ㅇㅇ
% EsN0 별테스트
SNR=5:10; % EsN0테스트 편의상 SNR
nslot=500; % 원래500개인데 너무많아
bler=zeros(length(SNR),1);
for j=1:length(SNR)
sfNum=1;
nTBerr=zeros(nslot,1);
fdchan = FDChan(carrierConfig, 'gain', gain, 'dly', dly, 'aoaAz', aoaAz, 'aoaEl', aoaEl, ...
    'rxVel', rxVel, 'Etx', Etx, 'EsN0Avg',SNR(j), 'fc', fc); %SNR만바꿈
rx = NRUERxFD(carrierConfig, pdschConfig, 'targetCodeRate', targetCodeRate);
for i=1: nslot % i는 1슬롯
    txGrid=tx.step(); % 1슬롯씩 랜덤으로 생성해줌
    sfNum = floor((i-1)/8) + 1; % 8슬롯1서브프레임 9슬롯부터 2서브
  [rxGrid, chanGrid, noiseVar]=fdchan.step(txGrid,sfNum,i); % 채널적용~
  rx.step(rxGrid,chanGrid,noiseVar); % rx 디코딩~

  nTBerr(i)= any(tx.txBits{1} ~= rx.rxBits); % 하나라도 틀리면 1

  if sum(nTBerr) >=50
      break
  end

end
bler(j)=sum(nTBerr) ./ i ;
end
figure;
plot(SNR,bler);
xlabel('EsN0(dB)')
ylabel('bler')
ylim([-0.01 1.01])

%% --문제 12:  샤논용량하고 뭘 비교하라는데 Blog2(1+snr) (bits/s)  인데
% 여기서는 log(1+Es/No*|h|^2) 왜? Es/No*|h|^2 <이게 최종SNR이라  
% 평균snr에 채널pow를 곱해야 진짜 수신 snr이나와서
c = abs(chanGrid).^2 / mean(abs(chanGrid).^2); % 왜채널을 정규화?(이미했는데?)
                                              % 평균 snr이 진짜 snr이되게해야해서
                                              % 채널power를 
                                              
seShannon = mean( log2( 1 + c*db2pow(SNR)) ); % bits/s/Hz=bps/Hz < 이거하라는데
plot(SNR,seShannon);% 5dB만 되도 MCS13에서의 bps/Hz 1.93을달성할수있는데
                    % 실제로 오류없이 되려면 8dB 즉+3dB이  더필요하다 ㅇ
