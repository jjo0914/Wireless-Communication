Lab2 : 전파모델실습, Ray tracing은 무선 적용범위를 예측하기 위한 3D 시뮬레이션  
  
코드흐름  
시뮬레이션된 결과를 불러오고 수신기와 송신기 사이의 path loss를 계산
->시뮬레이션결과의 지연시간과 송수신기 거리를 비교하여 LOS or NLOS분류    
->LOS or NLOS 데이터에 선형회귀 모델 fitting( 식 : a+10blog10(dist) ) (fitlm)    
->  링크상태를 예측하기위해 다항회귀모델 (fitmnr)사용 ->링크상태 예측  
  
Lab2.m: 메인스크립트
pathdata.m: 레이트레이싱 결과
map.png: 시뮬레이션 환경
