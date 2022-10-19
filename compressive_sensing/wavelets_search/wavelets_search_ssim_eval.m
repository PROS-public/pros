tic
n=5;
M=5;
w=10;
parfor (i=1:n,M)
    wavelets_search_ssim(i,w); 
end
toc