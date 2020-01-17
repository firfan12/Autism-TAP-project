file_tag = 'Suliman'

%beep_threshold = .1 % A
beep_threshold = .75;% Isaac;
%tap_threshold = .06;
tap_threshold = .02;
sync_channel = 41;
%%

tap_audio = audioread(strcat(file_tag, '_TAP.wav'));
beep_audio = audioread(strcat(file_tag, '_RR.wav'));
           
tap_audio_filt_2 = tap_audio(:,1);
%%

d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
               'DesignMethod','butter','SampleRate',44100);

           
tap_audio_filt = filtfilt(d,tap_audio(:,1));

%%
Fs = 44100; 
dft = fft(tap_audio_filt(1:60000000));
dft = dft(1:60000000/2+1);
DF = Fs/60000000; % frequency increment
freqvec = 0:DF:Fs/2;
plot(freqvec,abs(dft))

%%
d2 = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',84,'HalfPowerFrequency2',86, ...
               'DesignMethod','butter','SampleRate',44100);
d3 = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',118,'HalfPowerFrequency2',122, ...
               'DesignMethod','butter','SampleRate',44100);
           
d4 = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',168,'HalfPowerFrequency2',172, ...
               'DesignMethod','butter','SampleRate',44100);
d5 = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',253,'HalfPowerFrequency2',257, ...
               'DesignMethod','butter','SampleRate',44100);
d6 = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',338,'HalfPowerFrequency2',342, ...
               'DesignMethod','butter','SampleRate',44100);

Dhigh = designfilt('highpassfir','StopbandFrequency',240,'PassbandFrequency',250,'PassbandRipple',.5,'StopbandAttenuation',65,'DesignMethod','kaiserwin', 'SampleRate',44100);
Dlow = designfilt('lowpassfir','StopbandFrequency',320,'PassbandFrequency',300,'PassbandRipple',.5,'StopbandAttenuation',65,'DesignMethod','kaiserwin', 'SampleRate',44100);
 

tap_audio_filt_2 = tap_audio_filt;
tap_audio_filt_2(1:60000000) = filtfilt(d6, filtfilt(d5, filtfilt(d4, filtfilt(d3, filtfilt(d2,tap_audio_filt(1:60000000))))));

%%

wav_beep_times = get_times(beep_audio, beep_threshold)
wav_tap_times = get_times(tap_audio_filt_2, tap_threshold)

block_struct = divide_data(wav_beep_times, wav_tap_times, all_blocks_shuffled)


%%

n_block = 1;
block_struct_w_eeg = block_struct;
block_struct_w_eeg{n_block}.eeg_event_times = [];

i = 2;
counter = 1;
look_ahead = 2*params.sync_eeg_samples;

events_w_taps = [];
collecting = false;

while i < size(EEG.data, 2)-look_ahead
    %if EEG.data(sync_channel, i)-EEG.data(sync_channel, i-1)>500
    if EEG.data(sync_channel, i)>1400
        if EEG.data(sync_channel, i+1+look_ahead)>1400
            %counter = counter+1;
            if EEG.data(sync_channel, i+1+2*look_ahead)>1400
                if collecting & length(block_struct_w_eeg{n_block}.eeg_event_latencies)==length(block_struct_w_eeg{n_block}.code)
                    block_struct_w_eeg{n_block}.complete = true;
                end
                
                if ~collecting
                    n_block = n_block+1;
                end
            
                block_struct{n_block}.eeg_tap_times = block_struct{i}.wav_tap_times + block_struct{i}.eeg_beep_times(1) - block_struct{i}.wav_beep_times(1);    
                block_struct{n_block}.eeg_tap_latencies = floor(block_struct{n_block}.eeg_tap_times*512);
                collecting = false;
                
                if block_struct_w_eeg{n_block}.complete
                    for n = 1:length(block_struct_w_eeg{n_block}.code)
                        events_w_taps(end+1).latency = block_struct_w_eeg{n_block}.eeg_event_latencies(n);
                        events_w_taps2(end).duration = 0;
                        events_w_taps2(end).chanindex = 0;
                        events_w_taps2(end).urevent = counter;
                        events_w_taps2(end).type = block_struct_w_eeg{n_block}.code(n);
                        counter=counter+1;
                    end
                    for n = 1:length(block_struct_w_eeg{n_block}.code)
                        events_with_taps(end+1).latency = block_struct_w_eeg{n_block}.eeg_tap_latencies(n);
                        events_with_taps(end).duration = 0;
                        events_with_taps(end).chanindex = 0;
                        events_with_taps(end).urevent = counter;
                        events_with_taps(end).type = block_struct_w_eeg{n_block}.trial_tag*100 + 10000;
                        counter=counter+1;
                    end
                end
            else
                n_block = n_block + 1;
                collecting = true;
            end
        else
            if collecting
                block_struct_w_eeg{n_block}.eeg_beep_latencies(end+1) = i-1;
                block_struct_w_eeg{n_block}.eeg_beep_times(end+1) = (i-1)/512;
            end
        end
        i = i+3*look_ahead;
        'boing'
    end
    i = i+1;
end