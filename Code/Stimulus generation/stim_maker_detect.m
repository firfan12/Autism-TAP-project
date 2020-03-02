function block=stim_maker_detect(filename, n_trials, n_cues, cue_delay_generator, intertrial_interval_generator, bell, trial_tag, params)

identities = [];
intervals = [];

for i = 1:n_trials
    for j = 1:n_cues
        identities(end+1) = params.standard_index;
        intervals(end+1) = cue_delay_generator(i);
    end
    
    difficulty = floor(rand()*params.n_detect_difficulties)+1;
    pitch = floor(rand()*params.n_detect_pitches)+1;
    id = params.get_detect_id(pitch, difficulty)
    
    identities(end+1) = id;
    
    intervals(end+1) = intertrial_interval_generator(i);
    
    if bell
        identities(end+1) = params.bell_index;
        intervals(end+1) = 4;
    end

end

block = struct();

block.sound=master_stim_maker(filename, intervals, identities, params);
block.params = params;

block.trial_tag = trial_tag;
block.code = mod(identities,100) + 100*trial_tag;
block.intervals = intervals;
block.identities = identities;
block.type = 'detect';

if params.save_separate
    save(strcat(filename, '.mat'),'block');
end
