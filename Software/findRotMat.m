function rotation_matrix = findRotMat(arr)  
    
    debug = false;

    if debug
        % Prompt the user for a point on the planar surface
        disp('Enter a point on the plane (x ∈ [16, 19], y ∈ [-x, x], z ∈ [0, x]):');
        x_input = input('x-coordinate: ');
        y_input = input('y-coordinate: ');
        z_input = input('z-coordinate: ');
                
        % Validate the input point
        if ~((x_input <= 19 && x_input >= 16) && (y_input <= x_input && y_input >= -x_input) && (z_input <= x_input && z_input >= 0))
            error('Point is not on the planar surface. Please try again.');
        end
    else
        y_input = arr(2);
        z_input = arr(3);
        x_input = arr(1);
    end
    
    % Define the vertices of the planar surface
    vertices = [-x_input, x_input, x_input;
                 x_input, x_input, x_input;
                -x_input,  0, x_input;
                 x_input,  0, x_input];
    
    % Define the point and vector from the origin
    point_on_plane = [x_input, y_input, z_input];
    vector = point_on_plane - [0, 0, 0];
    unit_vector = vector / norm(vector); % Normalize the vector
    
    % Compute the rotation matrix to align the new X-axis with the vector
    % Step 1: The new X-axis is the direction of the vector
    new_x = unit_vector;
    
    % Step 2: Determine a perpendicular vector for the new Y-axis
    % Arbitrary cross-product with a reference vector to find a perpendicular vector
    if abs(new_x(1)) < abs(new_x(2)) && abs(new_x(1)) < abs(new_x(3))
        ref_vector = [1, 0, 0];
    else
        ref_vector = [0, 0, 1];
    end
    new_y = cross(new_x, ref_vector);
    new_y = new_y / norm(new_y); % Normalize the new Y-axis
    
    % Step 3: Determine the new Z-axis as perpendicular to both new X and Y
    new_z = cross(new_x, new_y);
    
    % Step 4: Construct the rotation matrix with manual 90 degree rotation about x'
    rotation_matrix = [new_x; new_y; new_z]' * [1 0 0; 0 0 -1; 0 1 0] * [1 0 0; 0 -1 0; 0 0 -1];
    
    if debug
        % Extract angles for reference
        theta_x = atan2(rotation_matrix(3, 2), rotation_matrix(3, 3));
        theta_y = atan2(-rotation_matrix(3, 1), sqrt(rotation_matrix(3, 2)^2 + rotation_matrix(3, 3)^2));
        theta_z = atan2(rotation_matrix(2, 1), rotation_matrix(1, 1));
        
        % Display the resulting rotation matrix
        disp('Rotation Matrix to align X-axis with vector:');
        disp(rotation_matrix);
        
        % Display angles for rotations
        disp(['Rotation about X-axis: ', num2str(theta_x * (180/pi)), ' degrees']);
        disp(['Rotation about Y-axis: ', num2str(theta_y * (180/pi)), ' degrees']);
        disp(['Rotation about Z-axis: ', num2str(theta_z * (180/pi)), ' degrees']);
        
        % 3D Plot Visualization
        figure;
        hold on;
        grid on;
        axis equal;
        xlabel('X-axis');
        ylabel('Y-axis');
        zlabel('Z-axis');
        title('3D Rotation and Vector Visualization');
        
        % Plot the planar surface
        fill3(vertices([1, 2, 4, 3], 3), vertices([1, 2, 4, 3], 1), vertices([1, 2, 4, 3], 2), ... % Swap Y and Z
              'cyan', 'FaceAlpha', 0.3);
        
        % Plot the vector from origin to the input point
        quiver3(0, 0, 0, vector(1), vector(2), vector(3), 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 2);
        text(vector(1), vector(2), vector(3), 'Input Vector', 'FontSize', 12, 'Color', 'r');
        
        % Plot the original coordinate axes
        quiver3(0, 0, 0, 10, 0, 0, 0, 'k', 'LineWidth', 1); % X-axis
        text(10, 0, 0, 'X', 'FontSize', 12);
        quiver3(0, 0, 0, 0, 10, 0, 0, 'k', 'LineWidth', 1); % Y-axis (was Z)
        text(0, 10, 0, 'Y', 'FontSize', 12);
        quiver3(0, 0, 0, 0, 0, 10, 0, 'k', 'LineWidth', 1); % Z-axis (was Y)
        text(0, 0, 10, 'Z', 'FontSize', 12);
        
        % Plot the rotated coordinate axes at the tip of the vector
        tip = vector; % Translate axes to the vector's endpoint
        rotated_x = rotation_matrix * [10; 0; 0];
        rotated_y = rotation_matrix * [0; 10; 0];
        rotated_z = rotation_matrix * [0; 0; 10];
        
        quiver3(tip(1), tip(2), tip(3), ...
                rotated_x(1), rotated_x(2), rotated_x(3), 0, 'b', 'LineWidth', 1); % Rotated X-axis
        text(tip(1) + rotated_x(1), tip(2) + rotated_x(2), tip(3) + rotated_x(3), ...
             'X''', 'FontSize', 12, 'Color', 'b');
        
        quiver3(tip(1), tip(2), tip(3), ...
                rotated_y(1), rotated_y(2), rotated_y(3), 0, 'g', 'LineWidth', 1); % Rotated Y-axis
        text(tip(1) + rotated_y(1), tip(2) + rotated_y(2), tip(3) + rotated_y(3), ...
             'Y''', 'FontSize', 12, 'Color', 'g');
        
        quiver3(tip(1), tip(2), tip(3), ...
                rotated_z(1), rotated_z(2), rotated_z(3), 0, 'm', 'LineWidth', 1); % Rotated Z-axis
        text(tip(1) + rotated_z(1), tip(2) + rotated_z(2), tip(3) + rotated_z(3), ...
             'Z''', 'FontSize', 12, 'Color', 'm');
        
        % Enable 3D rotation
        rotate3d on;
        
        hold off;
    end
end