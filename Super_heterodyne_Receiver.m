%*************************** Super-heterodyne Receiver*******************%
clear all;
clc ;
% read sounds 
[Sound1,FS]=audioread("Short_QuranPalestine.wav");
%[Sound2,FS]=audioread("Short_FM9090.wav");
[Sound2,FS]=audioread("D:\3rd year\Communications\CODES\New folder\Project\Short_SkyNewsArabia.wav");


% get sizes
Length_Sound1 = length(Sound1);
Length_Sound2 = length(Sound2);
if(Length_Sound1>Length_Sound2)
    Sound2=wextend('ar','zpd',Sound2,(Length_Sound1-Length_Sound2),'d');
elseif (Length_Sound2>Length_Sound1)
    Sound1=wextend('ar','zpd',Sound1,(Length_Sound2-Length_Sound1),'d');
end

%make signal Monophonic
Sound1(:,1)=Sound1(:,1)+Sound1(:,2);
Sound1(:,2) = [];
Sound2(:,1)=Sound2(:,1)+Sound2(:,2);
Sound2(:,2) = [];

%achieving Nyquist rule=10*FS
Message1=interp(Sound1 , 10 ) ;
Message2=interp(Sound2 , 10 ) ;

% F(new)=10*FS
FS = FS * 10 ;

%get n for Carrier
N = length(Message1) ;

TS = 1/FS ;     %get time 
Stop_Time=N/FS; %get stop time
t = (0:TS:Stop_Time-TS)';
Carrier1 = cos(2*pi*100*1000*t) ;
%carrier2 with 100+50n KHZ
Carrier2 = cos(2*pi*(100+50)*1000*t) ;
%get frequency responce of Two Messages
Message1_Spectrum=fft(Message1);
Message2_Spectrum=fft(Message2);

k=-N/2:N/2-1;
%figure
%plot(k*FS/N,fftshift(abs(Message1_Spectrum)));
%xlabel('Frequency');
%title('Message1 Spectrum');
%figure
%plot(k*FS/N,fftshift(abs(Message2_Spectrum)));
%xlabel('Frequency');
%title('Message 2 Spectrum');

%Modulating signals
Transmitter1_Sound=Message1.*Carrier1 ;
Transmitter2_Sound=Message2.*Carrier2 ;
% Create The Frequency Division Multiplexed Signal By Addition Of The Modulated Signals
Transmitter_Output=Transmitter1_Sound+Transmitter2_Sound;
%plotting spectrum of the channel
% perform FFT on signal
FDM = fft(Transmitter_Output );  

%figure
%plot(k*FS/N,fftshift(abs(FDM)));
%xlabel('Frequency');
%title('Frequency Division Multiplexing Spectrum'); 

%*********RF Stage**********%
%*****choose The Channel*******%
% Choose The Required Audio Signals
disp (" ");
disp ("*********Channels******** ");
disp ("1. Short Quran Palestine: 100 KHz");
disp ("2. Short Sky News Arabia 150 KHz");
%disp ("3. Russian Voice On Carrier: 200 KHz");
Freq_Channel = input ("Please Select The Desired Channel Frequency in KHz: ");
Freq_Channel = 1000 * Freq_Channel;    % convert it to KHZ

%design BPF for First sound
Fstop1=Freq_Channel-24000;  % Edge of the stopband
Fpass1=Freq_Channel-22000;  % Edge of the passband
Astop1=80;     % Attenuation in the first stopband
Fpass2=Freq_Channel+22000;   % Closing edge of the passband
Fstop2=Freq_Channel+24000;    % Edge of the second stopband
Astop2=80;         % Attenuation in the second stopband
Apass=0.001;             % Amount of ripple allowed in the passband
%specs of Bpf
BPF_specs=fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
    Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass,Astop2,FS);
BPF = design(BPF_specs);
RF_Message= filter(BPF,Transmitter_Output);
RF=fft(RF_Message);
%figure
%plot(k*FS/N,fftshift(abs(RF)));
%xlabel('Frequency');
%title(' BPF Outout'); 


%********** Mixer********%
Freq_IF=25000;
Mixer_Carrier=cos(2*pi*(Freq_IF+Freq_Channel)*t);
Mixer_Output=RF_Message.*Mixer_Carrier;
Mixer_Output_FFT=fft(Mixer_Output);
%figure
%plot(k*FS/N,fftshift(abs(Mixer_Output_FFT)));
%xlabel('Frequency');
%title('Mixer Output');
%ylabel('Mixer Output');
%Mixer to get second Sound

%*********IF Stage***********%
%Design Baseband BPF
Fstop1=Freq_IF-24000;  % Edge of the stopband
Fpass1=Freq_IF-22000;  % Edge of the passband
Astop1=80;     % Attenuation in the first stopband
Fpass2=Freq_IF+22000;  % Closing edge of the passband
Fstop2=Freq_IF+24000;  % Edge of the second stopband
Astop2=80;     % Attenuation in the second stopband
Apass=0.001;        % Amount of ripple allowed in the passband
BPF_specs=fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2', ...
    Fstop1, Fpass1, Fpass2, Fstop2, Astop1, Apass,Astop2,FS);
BPF = design(BPF_specs);
%fvtool(BPF)     %response of filter
IF_Output= filter(BPF,Mixer_Output);
IF_Output_FFT=fft(IF_Output);
 
%figure
%plot(k*FS/N,fftshift(abs(IF_Output_FFT)));
%xlabel('Frequency');
%title('IF Stage Output');

%***********Baseband Detection*************%
Carrier_Detection=cos(2*pi*25000*t);
Detection_Output=IF_Output.*Carrier_Detection;
Detection_Output_FFT=fft(Detection_Output);
figure
%plot(k*FS/N,fftshift(abs(Detection_Output_FFT)));
%xlabel('Frequency');
%title('Baseband Detection Output');

%******Filter******%
F_pass = 22000; % Edge of the lowband
F_stop = 24000; % Edge of the stopband
A_pass = 0.001; % Amount of ripple allowed in the band
A_stop = 80; % Attenuation in the band
LPF_specs=fdesign.lowpass('Fp,Fst,Ap,Ast', ...
    F_pass, F_stop, A_pass, A_stop, FS);
LPF = design(LPF_specs);
LPF_Output= filter(LPF,Detection_Output);
LPF_Output_FFT= fft(LPF_Output);
%figure
%plot(k*FS/N,fftshift(abs(LPF_Output_FFT)));
%xlabel('Frequency');
%title('Output after Low Pass Filter');
LPF_Output=4.*LPF_Output;
Reciever=downsample(LPF_Output,10);
sound(Reciever,FS/10);
