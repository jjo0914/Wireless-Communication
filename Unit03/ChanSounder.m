classdef ChanSounder < matlab.System
    % TX and RX channel sounder class

    properties
        
        nfft;  % number samples per frames
        seed;  % random generator seed 
        nframesTx;   % number of TX frames 

        x0fd;  % one frame of the frequency-domain TX signal
        x0;    % one frame of the time-domain TX signal


 
    end

    methods
        function obj = ChanSounder(opt)
            % Constructor

            arguments
                opt.nfft (1,1) {mustBeInteger} = 1024;
                opt.nframesTx (1,1) {mustBeInteger} = 32;
                opt.seed = 'default';
            end

            % Set the parameters
            obj.nfft = opt.nfft;    
            obj.nframesTx = opt.nframesTx;    
            obj.seed = opt.seed;

         
        end

        function xtx = getTx(obj)
            % Creates a random transmit sounding signal
            % 
            % Outputs
            % ------
            % xtx:  A complex sequence of length nframesTx * nfft
                        

            % Set the random seed so that the TX and RX will have the 
            % same seqeuence
            rng(obj.seed); % > RandStream.getGlobalStream 에서 난수를뽑아쓰는 함수들
                            %  rand, randi , randn, awgn 등등 통계관련함수거의전부 

            % TODO:  Use the qammod function to create nfft random QPSK symbols.
            % Store the symbol values in a column vector obj.x0fd
            %   obj.x0fd = ...
            %  qammod를 쓰기전에 비트부터 만들어야하지않나
            bits = randi([0 1], obj.nfft * 2, 1); % Generate random bits for QPSK
            obj.x0fd = qammod(bits, 4, 'InputType', 'bit','UnitAveragePower',true); % QPSK modulation

            % TOOD:  Create the time-domain signal in one frame 
            % by taking the IFFT of obj.x0fd.
            %     obj.x0 = ...
            obj.x0=ifft(obj.x0fd);


            % TODO:  Use the repmat command to repeat the TX signal 
            % obj.x0 obj.nframesTx times and output the signal in xtx.  
            % Since obj.x0 is obj.nfft  samples long, the resulting signal
            % xtx should be obj.nfft * obj.nframesTx long.
            %   xtx = ...            
            xtx=repmat(obj.x0,obj.nframesTx,1);
        end

        function [hest, hestFd] = getChanEst(obj, y)
            % Estimates the time-varying channel
            %
            % Inputs
            % ------
            % r:  nfft*nframe length RX signal
            %
            % Outputs
            % -------
            % hestFd:  nfft x nframe matrix of the frequency-domain channel
            %    in each frame
            % hestTd:  Time-domain version of the channel

            % 수집한 신호의 대략적인 프레임 개수는?
            nframeRx = floor(length(y) / obj.nfft);

            % Reshape y into a nfft x nframes matrix
            ymat = reshape(y(1:nframeRx*obj.nfft), obj.nfft, nframeRx); % 혹시 y가덜 길 경우대비

            % TODO:  Take the FFT of each column of ymat and store in yfd
            %  yfd = ... 
            yfd=fft(ymat,obj.nfft,1); % 각 1 열마다 fft해라
                
            
            % TODO:  Estimate the frequency domain channel by dividing each frame of
            % yfd by the transmitted frequency domain symbols x0Fd.  Store the results
            % in hestFd
            %   hestFd = ...
            % 이거근데.. 인덱스가 딱맞아야하지않아?
            hestFd=yfd./obj.x0fd; % 주파수

            % TODO:  Estimate the time-domain channel by taking the IFFT
            % of each column of hestFd
            %   hest = ...
            hest=ifft(hestFd);



        end       
            

    end



end

