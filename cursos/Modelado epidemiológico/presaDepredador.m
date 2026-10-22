function solution = presaDepredador(parameters,domain,input)

    simulation_steps = domain(1):domain(2);
    simulation_length = length(simulation_steps);
    states = zeros(2,simulation_length);

    states(1,1) = parameters(1); %Initial number of preys
    states(2,1) = parameters(2); %Initial number of predators

    alpha = parameters(3); %Reproduction number
    beta = parameters(4); % survival probability of predators
    mu = parameters(5); % natural mortality of preys
    eta = parameters(6); %velocity of interactions
    gamma = parameters(7); % probability or survival of preys after encounter with predator
    delta = parameters(8); % Number of new predators per comsumed prey

    for k = 1:(simulation_length-1)
        if input.kind == 1
            predation = (1-exp(-states(1,k)*states(2,k)/(eta*1e5)))*(1-gamma);
        else
            if states(1,k)>1
                predation = (1-(1-1/states(1,k))^(states(2,k)*(states(1,k)/(eta*1e3))^2))*(1-gamma);
            else
                predation=0;
            end
        end
        states(1,k+1) = states(1,k)*(1-predation)*(1-mu)*(1+alpha);
        states(2,k+1) = beta*states(2,k)+states(1,k)*predation*delta;
    end

    solution = struct();
    solution.x=simulation_steps;
    solution.y=states;

end