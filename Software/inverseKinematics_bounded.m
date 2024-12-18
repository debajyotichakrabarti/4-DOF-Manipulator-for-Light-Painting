function [angles] = inverseKinematics_deb(posMat, link_params, current_config)
    % Inputs:
        % Desired transformation matrix (HTM) of end effector wrt. the base
        % Link parameters (link lengths in this case)
        % Current_config: Current joint configuration of the arm [theta1, theta2, theta3, theta4] in degrees
    
    % Output:
        % Theta angles in degrees
 
    % Notes: 
        % Design link lengths such that (a3 * cos(theta3) + a2) != 0
    
    %% Input Processing
    % Position vector
    P = [posMat(1) posMat(2) posMat(3)]; % [x y z]

    % Rotation matrix
    r = findRotMat(P); 

    % Link parameters; no change by default (escape character: -1)
    try link_params == -1;
        link_params = [10 15 15 4]; % [a1 a2 a3 a4]
    end
    
    % Assign link parameters
    a1 = link_params(1);
    a2 = link_params(2);
    a3 = link_params(3);
    a4 = link_params(4);
    
    % HTM
    A = [r(1, 1) r(1, 2) r(1, 3) P(1);
         r(2, 1) r(2, 2) r(2, 3) P(2);
         r(3, 1) r(3, 2) r(3, 3) P(3);
         0       0       0       1]; 

    a1 = link_params(1);
    a2 = link_params(2);
    a3 = link_params(3);
    a4 = link_params(4);
    
    current_config = current_config * pi / 180;
    
    %% Singularity Check
    singularity_tolerance = 1e-6;
    if abs(a3*cos(0) + a2) < singularity_tolerance
        error('Singularity detected: a3*cos(theta3) + a2 is near zero. Adjust link parameters or avoid this configuration.');
    end
      
    %% Solving for Angles
    % Solve for theta1
    t1 = atan2(A(1,3), -A(2,3));
    
    % Solve for theta2+theta3+theta4
    t234 = atan2(A(3,1), A(3,2));
    cost_234 = A(3,2);
    sint_234 = A(3,1);
    
    % Solve for theta3
    store0 = cos(t1);
    if(abs(store0) <= singularity_tolerance)
        term1 = A(2,4)/sin(t1);
    else
        term1 = A(1,4)/cos(t1);
    end
    
    alpha = term1 - a4*cost_234;
    beta = A(3,4) - a1 - a4*sint_234;
    
    cost_3 = ((alpha^2+beta^2)-(a3^2+a2^2))/(2*a2*a3);
    sint_3 = [sqrt(1-(cost_3)^2);...
             -sqrt(1-(cost_3)^2)];
    
    store1 = sint_3(1,1);
    
    if(store1 ~= 0)
        t3 = atan2(sint_3,cost_3); % column vector
    else
        t3 = atan2(store1,cost_3); % scalar
    end
    
    % Solve for theta2
    t20 = [];
    if(store1 ~= 0)
        M = a3 * cost_3 + a2;
        for i = 1:2  % i corresponds to each theta3
            N(i,1) = a3*sint_3(i,1); % NOTE: M is a scalar but N is a vector
            matr = [M N(i,1);-N(i,1) M];
            vec =[beta;alpha];
            soln = inv(matr)*vec;
            sin_term = soln(1,1); cos_term= soln(2,1);
            t2_out = atan2(sin_term,cos_term);
            t20 = [t20; t2_out]; % t2 is a vector, each row corr. particular theta3
        end
    else
        t20 = atan2(beta,alpha); % t2 is a scalar
    end
     t2=[];
    for i=1:length(t20)
        if(t20(i)<0)
            continue;
        else
            t2=[t2;t20(i)];
        end
    end

    if(isempty(t2))
        disp('Error: No theta2 solution available')
        pause()
    end
    
    % Solve for theta 4
    t4 = t234-(t3+t2);
    % roll off t4 between 0 deg and +/-180 deg
    t4 = mod(t4 + pi, 2*pi) - pi;
    
    %% Cost Minimization; Solution Selection
    paths = [];
    for i = 1:length(t2)
        paths = [paths; [t1, t2(i), t3(i), t4(i)]];
    end
    
    costs = zeros(size(paths, 1), 1);
    for i = 1:size(paths, 1)
        costs(i) = norm(paths(i, :) - current_config); % Euclidean distance
        % disp("Optimizing...")
    end
    [~, best_path_idx] = min(costs);
    best_path = paths(best_path_idx, :);
    
    %% Output Processing
    angles = best_path * 180 / pi; % Return the best path in degrees
end

% T0_tool=
% [cos(t2 + t3 + t4)*cos(t1), -sin(t2 + t3 + t4)*cos(t1),  sin(t1), cos(t1)*(a3*cos(t2 + t3) + a2*cos(t2) + a4*cos(t2 + t3 + t4))]
% [cos(t2 + t3 + t4)*sin(t1), -sin(t2 + t3 + t4)*sin(t1), -cos(t1), sin(t1)*(a3*cos(t2 + t3) + a2*cos(t2) + a4*cos(t2 + t3 + t4))]
% [        sin(t2 + t3 + t4),          cos(t2 + t3 + t4),        0,      a1 + a3*sin(t2 + t3) + a2*sin(t2) + a4*sin(t2 + t3 + t4)]
% [                        0,                          0,        0,                                                             1]