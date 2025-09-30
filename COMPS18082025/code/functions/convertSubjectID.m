function [subjectIDNumberConverted, subjectIDNumber] = convertSubjectID(subjectIDFilePath)

    load(subjectIDFilePath);
    
    subjectIDNumberConverted = str2double(subjectIDNumber(1:4));

    if strcmp(subjectIDNumber(6:7), 'T1')
        subjectIDNumberConverted = subjectIDNumberConverted + 200;
    end
    
end
