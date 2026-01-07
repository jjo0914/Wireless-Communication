classdef FDChan < matlab.System
    % Frequency-domain multipath channel
    properties
        % Configuration
        carrierConfig;   % Carrier configuration
        
        % Path parameters
        gain;  % Path gain in dB
        dly;   % Delay of each path in seconds
        aoaAz, aoaEl; % Angle of arrival of each path in degrees      
        fd;    % Doppler shift for each path
        
        rxVel = [30,0,0]';  % Mobile velocity vector in m/s
        fc = 28e9;    % Carrier freq in Hz
        
        gainComplex;  % Complex gain of each path
        
        % SNR parameters
        Etx = 1;       % average energy per PDSCH symbol 
        EsN0Avg = 20;  % Avg SNR per RX symbol in dB
       
        % Symbol times
        symStart;  % symStart(i) = start of symbol i relative to subframe
                     
    end
    methods
        function obj = FDChan(carrierConfig, varargin)
            % Constructor
            c=physconst('LightSpeed');
            % Save the carrier configuration
            obj.carrierConfig = carrierConfig;

                                 
            % Set parameters from constructor arguments
            if nargin >= 1
                obj.set(varargin{:});
            end
            
            % TODO:  Create complex path gain for each path
            %   obj.gainComplex = ... 
            % 식참조 주파수 영역에서 
            % H=sqrt(received Energy) * exp^-2pij(T k(행) fd + S(sc간격)n t(Delay) + 초기위상)
            powgain=db2pow(obj.gain); % 주파수영역도 그냥같은듯?
            % gain은 정규화할필요가없나봐 나중에정규화할거라
           % powgain = powgain / sum(powgain);% 합=1 정규
            phi0=2*pi*rand(length(obj.gain),1); % 라디안 ㅇ
            obj.gainComplex=sqrt(powgain) .* exp(1j*phi0); % 2*1 행벡터
            
            % TODO:  Compute the Doppler shift for each path
            %    obj.fd = ... -fc/c * |수신기속도| * cos (수신기벡터& 도착경로각도) (unit vector랑 내적 ㄱ)
            % Compute unit vector in direction of each path
               [ux,uy,uz]=sph2cart(deg2rad(obj.aoaAz),deg2rad(obj.aoaEl),1); % 라디안으로받음
                                                                   % 경로2개
             u=[ux uy uz];
             obj.fd=-obj.fc/c*u*obj.rxVel; % 행벡터 ㅇ
            
            
            % TODO:  Compute the vector of 
            % symbol times relative to the start of the subframe
            %    obj.symStart = ...            
            % Lab4의 ofdminfo쓰라는데?
            info=nrOFDMInfo(obj.carrierConfig); % carrier정보(NRB갯수)로는불충분
         
            obj.symStart=cumsum([0 info.SymbolLengths]) ./ info.SampleRate;  % Use 심볼길이(Nfft+CP)  + 샘플레이트                                                 
                                                                        % 오딱
                                                                        % 1ms나오는데?
                                                                        % 113열벡터
                                                                        % 1ms(112=원래갯수)
             obj.symStart= obj.symStart(1:length(info.SymbolLengths)); % 심볼갯수만 ㅇㅇ
        end
        
        
    end
    methods (Access = protected)
        
        
        function [rxGrid, chanGrid, noiseVar] = stepImpl(obj, txGrid, sfNum, slotNum)
            % Applies a frequency domain channel and noise
            %
            % Given the TX grid of OFDM REs, txGrid, the function
            % *  Computes the channel grid, chanGrid, given the 
            %    subframe number, sfNum, and slotNum, slotNum.
            % *  Computes the noise variance per symbol, noiseVar,
            %    for a target SNR
            % *  Applies the channel and noise to create the RX grid 
            %    of symbols, rxGrid.
            % H=sqrt(received Energy) * exp^-2pij(T k(행) fd + S(sc간격)n t(Delay) + 초기위상) 
          

            % 이거 txGrid가 1슬롯이넴>..=14ofdm Symbol 여기하고 CP붙는다
            % 792 Subcarrier +232(가드) =1024 nfft
            nsub=obj.carrierConfig.NSizeGrid*12; % 1RB=12 서브캐리어 ,66RB= 792 서브캐리어
            nsym=obj.carrierConfig.SymbolsPerSlot; % 5G는 txGrid를 1슬롯씩 보낸데 
            S=(0:(nsub-1)) .* obj.carrierConfig.SubcarrierSpacing*1e3; % 서브캐리어 첫번째인덱스= 0 
           S=S'; % S는 주파수축이라 행으로 바꿔주고
           % S가 DC중심으로해야되는지 0부터해야되는지 아직도모르겟음 예제는0부터 GPT는 DC중심..
           
            % 제일중요한 시간축 계산
            slotNum=mod(slotNum-1,8) + 1; % 8슬롯넘으면 1슬롯부터
            slotidx=(1:nsym)+nsym*(slotNum-1);
            K=obj.symStart(slotidx)+(sfNum-1).*1e-3; % 서브프레임1번넘으면 1ms
        
            chanGrid=zeros(length(S),length(K));
            for i=1:length(obj.dly)
                 chanGrid=chanGrid+obj.gainComplex(i) .* exp(2j*pi.*obj.fd(i) .* K + -2j*pi.*S.*obj.dly(i)) ; % 딜레이있음
            end
         
            
            
            
           % 이제노이즈는어케추가하지 주파수축이어도 power계산은 같은듯?
           % 일단 1w노이즈를 추가해
           EsN0=db2pow(obj.EsN0Avg);
           Noise=1/sqrt(2) .* (randn(size(chanGrid)) + 1i*randn(size(chanGrid)));
           noiseVar=1/EsN0; %필요한노이즈 파워. 송신심볼 1W니깐 (채널요소는생각X)
                        
           Noise=sqrt(noiseVar) .*Noise;% 작은노이즈만들고
           rxGrid=chanGrid .* txGrid +Noise;

           % % 여기검증 ㄱ
            %fprintf(" H power(평균): %.2f , gainComplex Power(sum) : %.2f  (같아야함.)\n",mean(abs(chanGrid(:).^2)), sum(abs(obj.gainComplex).^2))
            %fprintf(" Noise power : %.2f \n",noiseVar);
        end
        
    end
end

