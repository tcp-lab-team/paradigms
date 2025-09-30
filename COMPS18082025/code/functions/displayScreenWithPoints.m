function displayScreenWithPoints(window, screen, points, screenXpixels, screenYpixels)
	% displayImageWithPoints draws an image centered on screen, overlays points, updates the photodiode rectangle, and flips the screen.
	% Returns the destination rectangle used for drawing so callers can reuse it.
    Screen('DrawTexture', window, screen, [], [0 0 screenXpixels screenYpixels], 0,[], 1);
    drawPoints(window, points); % Re-add the points in black text to show on the white screen
    Screen('Flip', window);
end 