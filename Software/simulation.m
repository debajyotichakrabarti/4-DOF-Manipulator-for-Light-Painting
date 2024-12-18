function simulation_new(anglesMat, link_lengths)
    % simulation.m
    % Animates the robotic arm based on joint angles matrix and exports the animation to an MP4 file.
    %
    % Inputs:
    %   anglesMat - [Nx4] Matrix containing joint angles [theta1, theta2, theta3, theta4] in degrees
    %   link_lengths - [1x4] Link lengths [a1, a2, a3, a4] in meters

    % Convert angles from degrees to radians
    jointAngles_rad = deg2rad(anglesMat);

    % Time settings for animation
    numFrames = size(jointAngles_rad, 1);
    % pauseTime = 0.05; % Adjust based on desired animation speed (optional)

    % Initialize painting variables
    isPainting = false; % Whether the pen is down

    % Create the figure
    fig = figure('Name', 'Robotic Arm Animation', 'NumberTitle', 'off');
    hold on;
    grid on;
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    title('Robotic Arm Animation');
    axis equal;
    xlim([-0.3, 0.3]); % Adjust based on workspace (meters)
    ylim([-0.1, 0.4]);
    zlim([-0.1, 0.4]);
    view(45, 30);

    % Initialize arm plot (lines and joint markers)
    armPlot = plot3(NaN, NaN, NaN, 'b-', 'LineWidth', 2); % Line plot for the arm links
    jointMarkers = plot3(NaN, NaN, NaN, 'bo', 'MarkerSize', 6, 'MarkerFaceColor', 'b'); % Markers for joints

    % Initialize path plot using animatedline
    pathPlot = animatedline('Color', 'r', 'LineWidth', 2);

    % Set up video writer
    videoFileName = 'robotic_arm_animation.mp4';
    videoWriter = VideoWriter(videoFileName, 'MPEG-4');
    videoWriter.FrameRate = 20; % Adjust the frame rate as needed
    open(videoWriter);

    % Loop through each frame
    for i = 1:numFrames
        % Check for NaN values to determine if the pen should lift
        if any(isnan(jointAngles_rad(i, :)))
            isPainting = false; % Lift the pen
            continue; % Skip this frame without moving the arm
        else
            isPainting = true; % Pen is down
        end

        % Get the joint angles for this frame
        theta1 = jointAngles_rad(i, 1);
        theta2 = jointAngles_rad(i, 2);
        theta3 = jointAngles_rad(i, 3);
        theta4 = jointAngles_rad(i, 4);

        % Calculate the positions of each joint using FK
        [fx, fy, fz] = forwardKinematics([theta1; theta2; theta3; theta4], link_lengths);

        % Update the arm plot data (links)
        set(armPlot, 'XData', fx, 'YData', fy, 'ZData', fz);

        % Update the joint markers
        set(jointMarkers, 'XData', fx, 'YData', fy, 'ZData', fz);

        % If painting, add the end-effector position to the path
        if isPainting
            addpoints(pathPlot, fx(end), fy(end), fz(end));
        end

        % Update the title to show the current frame number
        title(['Frame: ', num2str(i)]);

        % Render the updates
        drawnow;

        % Capture the current frame
        frame = getframe(fig);
        %writeVideo(videoWriter, frame);

        % Pause for animation (optional)
        % pause(pauseTime);
    end

    % Close the video writer
    close(videoWriter);

    disp('Animation complete!');
    disp(['Video saved as ', videoFileName]);
end
