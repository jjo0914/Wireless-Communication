5G MATLAB toolbox를 활용하여  다운링크 송수신 체인 시뮬레이션  
  
1. 지정된 파라미터로 5g OFDM신호 자원할당  
2. 채널 상태를 가정 하고 OFDM Channel Grid 생성  
3. 채널의 SNR확인 (1슬롯)  
4. MCS13 PDSCH 전송그리드 생성(1Layer,랜덤비트)  
5. 1슬롯 내에 PDSCH 자원이 아닌 Grid 마스킹(가로선 :DM-RS(복조용 참조신호))  
6. PDSCH 심볼복조  
7. SNR에따른 PDSCH 비트복조&블록에러 확인 (비트 하나라도 오류나면 블록에러)  
8. SNR에서 샤논용량계산(bit/s/Hz)  
  
Lab4.m: 메인  
FDChan: OFDM 채널 시뮬레이션 코드  
NRgNBTxFD : OFDM TxGrid 시뮬레이션 (제공 스크립트)  
NRgNBRxFD : RxGrid 심볼 복조 및 비트 복호(제공 스크립트  
labPdsch : 문제  
