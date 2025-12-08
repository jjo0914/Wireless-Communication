classdef ElemWithAxes < matlab.System
    % ElemWithAxes:  An antenna element with a local frame of reference
    %
    % This class combines an antenna element from the phased array toolbox
    % along with a local coordinate system to facilitate geometric
    % computations.
    %
    % In addition, it provides smooth interpolation of the directivity
    % which is not performed in the phased array toolbox
    properties
        % The antenna object from the phased array toolbox
        ant = [];
        
        % Azimuth and elevation angle of the element peak directivity
        axesAz = 0;
        axesEl = 0;
        
        % Axes of the element local coordinate frame of reference
        axesLoc = eye(3);
        
        % Frequency in Hz
        fc = 28e9;
        
        % Directivity interpolant
        dirInterp = [];
        
        % Velocity vector in 3D in m/s
        vel = zeros(1,3);
    end
    methods
        function obj = ElemWithAxes(fc, ant)
            % Constructor
            % Inputs:  fc is the carrier frequency in Hz and ant is
            % an antenna compatible with the phased array toolbox.  It must
            % support the ant.pattern() method.
            
            % Set parameters
            obj.fc = fc;
            obj.ant = ant;
        end
        
        function alignAxes(obj,az,el)
            % Aligns the axes to given az and el angles
            
            % Set the axesAz and axesEl to az and el            
            obj.axesAz = az;
            obj.axesEl = el;
            
            %% 문제 5-1 : az,el을 받아서 azelaxes를 사용하고
            % r방향 단위벡터(1열),az방향 접선단위벡터(2열),el방향 접선단위벡터(3열) 얻기
            % 왜함? 몰라
            
            % TODO:  Use the azelaxes() function to create a 3 x 3 array
            % corresponding to an orthonormal basis for the local
            % coordinate system of the array aligned in the direction
            % (az,el).  Save this in the axesLoc property.
            %    obj.axesLoc = azelaxes(...);
            obj.axesLoc = azelaxes(az,el);
        end
        
        function dop = doppler(obj,az,el)
            % 도플러계산은 도착경로와 속도벡터사이 각도를 구해야하는데
            % =내적계산임 그냥

            % Computes the Doppler shift of a set of paths
            % The angles of the paths are given as (az,el) pairs
            % in the global frame of reference.

            % Get the number of paths
            npath = length(el);
            
            % TODO:  Use the sph2cart method to find unit vectors in the
            % direction of each path.  That is, create an array where
            % u(:,i) is a unit vector in the angle (az(i), el(i)).
            % Remember to convert from degrees to radians!
            %    [u1,u2,u3] = sph2cart(...);
            %    u = [u1; u2; u3];             
            [u1,u2,u3]=sph2cart(deg2rad(az),deg2rad(el),1); % 수신경로의 Unit벡터
            u=[u1;u2;u3]; % [u1
                          % u2 
                          % u3] 한 열이 하나의 좌표set

            % 도플러주파수 계산= -v * fc * cos() / c   |  cos()그냥내적계산
            c=physconst('LightSpeed');
            dop= -obj.vel*u*obj.fc/c ; % vel :행 , u: 열 벡터라 곱하면내적 ㅇ 

            % TODO:  Compute the Doppler shift of each path from the
            % velocity vector, obj.vel.  The Doppler shift of path i is
            %     dop(i) = obj.vel*u(:,i)*fc/vc,
            % where vc = speed of light
            %   dop = ...;
     
            
        end
        
    end
    
    methods (Access = protected)
        % 문제 6-1 : 클래스 생성시  따악 한번만 호출!
        function setupImpl(obj)
            % setup:  This is called before the first step.
            % We will use this point to interpolator
            
            % 안테나의 directivity 추출
            % TODO:  Get the pattern from ant.pattern   
            %     [dirPat,azPat,elPat] = obj.ant.pattern(...);
            [dirPat,azPat,elPat] = obj.ant.pattern(obj.fc); %  elPat(행 y)* azPat(얄 x축)
            

            % 5도마다 있는값을 더촘촘하게 값들 보간하는객체 생성
            % 없는 값을주면 보간해줌

            % TODO:  Create the gridded interpolant object.  You can follow
            % the demo in the antennas lecture
            %     obj.dirInterp = griddedInterpolant(...)
            obj.dirInterp= griddedInterpolant({elPat,azPat},dirPat); % 행,열
                                   
            
        end
        function dir = stepImpl(obj, az, el)
            % Computes the directivity along az and el angles
            % The angles are given in the global frame of reference
            % We do this by first rotating the angles into the local axes
           
          
            % 문제 9-1 : global2localcoord(원래점,'옵션',cart원점이동)받아서 좌표이동)
            % az ,el 각도를 안테나기준각도로 바꾼다
            uglobal=[az; el; ones(1,length(az))]; % [ az
                                                  %   el
                                                  %    r], r는 그냥1로둠
            ulocal= global2localcoord(uglobal,'ss',[0;0;0],obj.axesLoc); % 원점을그대로 축을바꿔
                                                                         % 가장강한경로로 축으로 좌표를 바꾸는 이유가뭐지
            azLoc=ulocal(1,:);% 바뀐좌표축의 az
            elLoc=ulocal(2,:);% 바뀐좌표축의 el

            % TODO:  Use the global2localcoord function to translate 
            % the gloabl angles (az(i), el(i)) into angles
            % (azLoc(i),elLoc(i)) in the local coordinate system.  use
            % the 'ss' option along with the local axes obj.axesLoc.ㄴㄴㄴ
            %     uglobal = [ax; el; ones(1,length(az)];
            %     ulocal = global2localcoord(...);
            %     azLoc = ulocal(1,:);
            %     elLoc = ulocal(2,:);
            
             % 문제9-2: 그때의 directivity??
             dir=obj.dirInterp(elLoc,azLoc); % 요것도 행 열값


            % TODO:  Run the interplationn object to compute the directivity
            % in the local angles
            %   dir = obj.dirInterp(...);
            
        end
        
        
    end
    
    
end

