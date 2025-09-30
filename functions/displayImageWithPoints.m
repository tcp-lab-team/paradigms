function dstRect = displayImageWithPoints(window, imageMatrix, points, photodiodeRect, black, screenXpixels, screenYpixels)
	% displayImageWithPoints draws an image centered on screen, overlays points, updates the photodiode rectangle, and flips the screen.
	% Returns the destination rectangle used for drawing so callers can reuse it.
	[imageHeight, imageWidth, ~] = size(imageMatrix);
	dstRect = CenterRectOnPointd([0 0 imageWidth imageHeight], screenXpixels / 2, screenYpixels / 2);
	imageAsTexture = Screen('MakeTexture', window, imageMatrix);
	Screen('DrawTexture', window, imageAsTexture, [], dstRect, 0, [], 1);
	drawPoints(window, points);
	Screen('FillRect', window, black, photodiodeRect);
	Screen('Flip', window);
end 