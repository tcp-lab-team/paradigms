
design.prob_standard = 0.9;
design.prob_deviant = 0.1;
design.n_trials = 1500; % Adjust as needed



% Generate the correct number of trials
design.trial_sequence = [ones(design.n_trials*design.prob_standard,1); ones(design.n_trials*design.prob_deviant,1)*2];

% Shuffle sequence to pseudorandomize
rng(999);
design.trial_sequence = design.trial_sequence(randi(design.n_trials,design.n_trials,1));
design.trial_timing = repmat(0.5,design.n_trials,1).*(1:design.n_trials)'+4.5; % we will tart after 5 seconds with the first tone

figure; plot(design.trial_sequence, '.'); ylim([1 4]);

save('mmn_design.mat', 'design');