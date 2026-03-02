% Lab 
% 데이터 load azi,ele,E-field(RMS)값존재

load patch_bottom_data.mat; %변수명은 data_table
el=data_table(:,'Elevation').Variables; % .Varaible안하면 talbe로읽어들여서 계산안댐
az=data_table(:,3).Variables;

el=el; % matlab 계산은 아래쪽이 -90도인데
        % 데이터는 위쪽을 -90도로 표현함


EV=data_table(:,5).Variables + 1i*data_table(:,6).Variables;
EH=data_table(:,7).Variables + 1i*data_table(:,8).Variables;

% S=|E|^2 / n  , W=1/2n *|E|^2 (E는젤큰걸로)
%                W=|E|^2/n   (RMS값)
Epow=abs(EV).^2+abs(EH).^2; % data에 있는거는 peak값 
                            % |E|^2 , 각방향에서의 전기장크기
                            % |E_rms|^2= |E|^2 / 2
% 이제 directivty(=4pi*U/구적분U)를 구해야되는데 U는 그방향으로 나가는 전력을의미
% U= r^2 |E|^2 /2*계수 인데  (|E|^2는 peak값)
% r과 계수들은 소거됨 
% 그래서 D= 4pi*E/구적분 E
% 구적분 E= sum(Epow. sin(el).*daz.*del)
% 구적분은 위쪽이 0도
daz=deg2rad(2);% 2도차이로기록
elrad=deg2rad(-el+90);  % 구적분은 위쪽이 0도 아래쪽(-90)이 180도
sphE=sum(Epow.*sin(elrad).*deg2rad(2).*deg2rad(2));
dir=4*pi.*Epow./sphE; % directivy의 구면 평균은  1.. (sum(dir .* sin(elrad) * deg2rad(2) * deg2rad(2)) / (4*pi))

%--------------Antenna Pattern 3d plotting--------
% matlab 좌표에맞게 각도새로생성
% 좌표값은 증가여만한데
elvals = (-90:2:90)'; % 하드코딩,el 2도마다 값이 있음
azvals = (-180:2:180); % % 360= -180 0=0, 180=180


% 현재 dir값은 16471개로 el크기*az크기임 ㅇㅇㅇ
dirMat=reshape(dir,length(elvals),length(azvals));

%
% 근데 az가 0~360도라 -180~180으로맞추려고
% 이거뭔가이상해서 x축회전 해볼게.. 원래대로보려면 주석
 dirMat=circshift(dirMat,90,2); % 1 아래로이동 2오른쪽으로이동
 % x축회전
[az,el]=meshgrid(azvals,elvals); % 181
x=cosd(el).*cosd(az);
y = cosd(el).*sind(az);
z = sind(el);
psiDeg=90; % 90도회전
c = cosd(psiDeg);
s = sind(psiDeg);

xp = x;
yp = y.*c - z.*s;
zp = y.*s + z.*c;
el2 = asind(zp);
az2 = atan2d(yp, xp);
el2= 2* round(el2/2);
az2= 2*round(az2/2);
% 바뀌면어떻게해야지
dirMat2=zeros(length(elvals),length(azvals));
for i=1:length(elvals)
    for j=1:length(azvals)
        [newi,~]=find(el2(i,j)==el,1);
        [~,newj]=find(az2(i,j)==az,1);
        dirMat2(i,j)=dirMat(newi,newj);
    end
end
dirMat2 = flipud(dirMat2);
  % 이상태에서 아래로 90도 밀고(45) 왼쪽으로 90돌밀면(90) 회전
% dirMat=circshift(dirMat,45,1);
% % dirMat=circshift(dirMat,90,1);
% % % 위에서 -90도를 90도취급한거를 다시 -90도로? ??
 % dirMat = flipud(dirMat);
                        
% dirMat=circshift(dirMat,-45,2); % 1 아래로이동 2오른쪽으로이동
% dirMat=circshift(dirMat,45,1); % 1 아래로이동 2오른쪽으로이동

fc=2.8e10;
% 위상은 정보가없다
phasePattern=zeros(size(dirMat2));
ant = phased.CustomAntennaElement( ...
    'AzimuthAngles',           azvals, ...
    'ElevationAngles',         elvals, ...
    'MagnitudePattern',        pow2db(dirMat2), ...
    'PhasePattern',            phasePattern );
% 3d 안테나 패턴 plotting
ant.pattern(fc); % -> phased array toolbox 필요 ㅜ
% 2d 안테나 패턴 plotting
%%
% half power beam width를 찾을건데
% half power= -3dB 
figure;
% Elevation pattern plotting at 0 degrees
ant.patternElevation(fc,0); % azimuth=0일때 -90~90도 
dircut=ant.patternElevation(fc,0); % 자른거 값 받기 
elcut = (-180:180); % 값순서는 -부터 원래 -90~90도값만필요해
                    % 나머지값은뭐지? -27.05?

dirmax=max(dircut); % 최대값찾기
