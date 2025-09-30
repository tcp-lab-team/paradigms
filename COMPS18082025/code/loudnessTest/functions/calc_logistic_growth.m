function K = calc_logistic_growth(f0, array_len)
    % Calculate the growth rate (K) given the 0th point percentage (f0) 
    % and the length of the array (array_len).

    % Ensure f0 is between 0 and 1
    if f0 <= 0 || f0 >= 1
        error('f0 must be a value between 0 and 1.');
    end
    
    % Calculate K using the algebraic form of the logistic function
    K = -2 * log((1 - f0) / f0) / (array_len - 1);
    
    return;
end
