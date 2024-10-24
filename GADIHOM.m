%% GADIHOM.m
% compute the inverse homogenization of a lattice
% Dos Reis F.
% 2021.02.13 -> 2022.04.04
function GADIHOM(nchromosomes,nkeep,rhov,seed,nkmax,target,wtarget,...
    mutrate,ntvalue,lambda,convergence,nConvergence)
%% data values
global L1 L2 Y1 Y2 Lb
L1=10 ; L2=10; %length of lattice directors 
Y1=[1 0];Y2=[0 1]; % definition of lattice directors assuming rectangular base cell
%% init variables
meanc=zeros(1,nkmax);   % mean cost
minc=zeros(1,nkmax); % min cost
MS4=zeros(nchromosomes,6); %contain compliance tensors of each chromosomes
MExtracted=zeros(nchromosomes,10);
cost=zeros(1,nchromosomes); % score of chromosomes
% global variables to mesh function
global nbeams nnodes nodes ;
global Ob;
global Eb;
global delta1;
global delta2;
global Elast; 

%% meshing 
Mesh(seed);   
Elast=210000*ones(1,nbeams) ; % matrix size (1 x nbeams)Value of elastic modulus
chromosomes=zeros(nchromosomes,nbeams);
ct=zeros(1,nbeams); % scale density value
cgene=0;    % counter of total gene created, reset when > 1/mutrate
nlowIter=0;
%% first generation
% initial chromosomes
for i=1:nchromosomes % ct calculus
    chromosomes(i,:)=ntvalue*rand(1,nbeams) ;% matrix size (1 x nbeams) of width
       temp1=Lb*chromosomes(i,:)';
        ct(1,i)=rhov*(L1*L2)/temp1;
end
% Homogenization & cost for each chromosome
for i=1:nchromosomes
    Tb=ct(1,i)*chromosomes(i,:);
    [MExtracted(i,:),MS4(i,:)]=homogenization(Tb);
    A=target;B=MS4(i,:);
    cost(1,i)=fcost(A,B,wtarget,lambda);
end
% Sort
[cost,ind]=sort(cost,'ascend'); % sort of chromosomes ascending
chromosomes=chromosomes(ind,:);  % update chromosomes from the best to the worst
meanc(1,1)=mean(cost);    % values first generation
minc(1,1)=min(cost);
% function of probability distribution
M=ceil((nchromosomes-nkeep)/2); % number of matings
prob=flipud([1:nkeep]'/sum([1:nkeep])); % weights chromosomes
odds=[0 cumsum(prob(1:nkeep))']; % probability distribution function 

%% loop
for iga=2:nkmax   % generation counter
    % Selection 
    pick1=rand(1,M); % mate #1 (vector of length M with random #s between 0 and 1)
    pick2=rand(1,M); % mate #2

    % ma and pa contain the indices of the chromosomes that will mate
    % Choosing integer k with probability p(k)
    ma=zeros(1,M);
    pa=zeros(1,M);
    for ic=1:M
        for id=2:nkeep+1
            if pick1(ic)<=odds(id) && pick1(ic)>odds(id-1)
                ma(ic)=id-1;
            end
            if pick2(ic)<=odds(id) && pick2(ic)>odds(id-1)
                pa(ic)=id-1;
            end
        end
        if (ma(ic)==pa(ic)) % for avoiding incest
            ma(ic)=ma(ic)+1;
        end
    end
    % Crossover, pair & mate
    xp=ceil(rand(1,M)*(nbeams-1)); % crossover point
    for i=1:M
        chromosomes(nkeep+i*2-1,:)=[chromosomes(ma(i),1:xp(i)) chromosomes(pa(i),xp(i)+1:nbeams)];
        chromosomes(nkeep+i*2,:)=[chromosomes(pa(i),1:xp(i)) chromosomes(ma(i),xp(i)+1:nbeams)];
    end 
    % Mutation 
    cgene=cgene+(nchromosomes-nkeep)*nbeams;  % j'opère une mutation uniquement sur les nouveaux chromosomes
    nmut=floor(cgene*mutrate);
    if nmut>1
        cgene=0;
        for i=1:nmut
            mutc=ceil((nchromosomes-nkeep)*rand());    % 
            mutg=ceil(nbeams*rand());
            chromosomes(nkeep+mutc,mutg)=ntvalue*rand();
        end
    end

    % update ct
    for i=1:nchromosomes 
       temp1=Lb*chromosomes(i,:)';

        ct(1,i)=rhov*(L1*L2)/temp1;
    end
    % Homogenization & cost for each chromosome 
    for i=1:nchromosomes
        Tb=ct(1,i)*chromosomes(i,:);
        [MExtracted(i,:),MS4(i,:)]=homogenization(Tb);
        A=target;B=MS4(i,:);
        cost(1,i)=fcost(A,B,wtarget,lambda);
    end
    % Sort
    [cost,ind]=sort(cost,'ascend'); 
    chromosomes=chromosomes(ind,:);  
    meanc(1,iga)=mean(cost);    
    minc(1,iga)=min(cost);
    iga
    minc(1,iga)
    bestIndex=ind(1);
        % convergence ?
    if ((abs(minc(1,iga)-minc(1,iga-1))/minc(1,iga))<convergence)
        nlowIter=nlowIter+1;
        if (nlowIter>nConvergence) 
            break;
        end
    else
        nlowIter=0;
    end
end
%% Results
clf;
plot(1:iga,minc(1,1:iga));
save_matrix("MS4.csv",MS4);
save_matrix("Ob.csv",Ob);
save_matrix("Eb.csv",Eb);
save_matrix("delta1.csv",delta1);
save_matrix("delta2.csv",delta2);
save_matrix("chromosomes.csv",chromosomes);
save_matrix("cost.csv",cost);
[Kh,Exh,Eyh,nuyxh,nuxyh,muxyh,etaxxyh,etayxyh,etaxyxh,etaxyyh] = mechanic_moduli(MS4(1,:));
mechanic_homogenized=[Kh,Exh,Eyh,nuyxh,nuxyh,muxyh,etaxxyh,etayxyh,etaxyxh,etaxyyh];
save_matrix("mechanic_homogenized.csv",mechanic_homogenized);
save_matrix("nodes.csv",nodes);
% test avec le premier chromosome
Tb=ct(1,bestIndex)*chromosomes(1,:);
Y1=L1*Y1;Y2=L2*Y2;
save_matrix("Tb.csv",Tb);




