clc
clear all
close all

coordinatesMatrix = motion(0, 60, 'Arial', 'normal', true)

currentConfig = [0 0 0 0]; % Initial position

for i = [1:height(coordinatesMatrix)]
    if isnan(coordinatesMatrix(i))
        anglesMat(i, :) = [NaN NaN NaN NaN];
    else
        %anglesMat(i, :) = inverseKinematics_bounded(coordinatesMatrix(i, :), -1, currentConfig);
        anglesMat(i, :) = inverseKinematics(coordinatesMatrix(i, :), -1, currentConfig);
        currentConfig = anglesMat(i, :);
    end
end

%simulation_new(anglesMat, [15 15 15 4])
