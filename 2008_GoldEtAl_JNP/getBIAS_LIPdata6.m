function rocs_ = getBIAS_LIPdata6(sid)
% function [wrd_,pd_,exdat_,wk_] = getBIAS_LIPdata5(sid, slopes, exd)

%global FIRA

% get tin
tin = getBIAS_tinFromFIRA(sid);

% get wk value
wk = getBIAS_wkFromFIRA(tin);

times = getFIRA_ecodesByName({'trg_on', 'dot_on', 'fp_off', 'sac_lat', 'dot_off'});
cohs  = getFIRA_ecodesByName('dot_coh')./100;
cors  = getFIRA_ecodesByName('correct');
stin  = sign(cos(tin*pi/180));
chcs  = stin.*sign(cos(getFIRA_ecodesByName('choice')*pi/180));
dirs  = stin.*sign(cos(getFIRA_ecodesByName('dot_dir')*pi/180));
Lcor  = cohs==0 | cors==1;
Lgood = getFIRA_ecodesByName('task')==6 & cors>=0 ;

% fit to PMF, with wk
ctdat = [cohs (times(:,5)-times(:,2))./1000 dirs chcs cors];
[fits,a,b,c,d,e]  = ctPsych_fit(@ddExp5fz_F, ctdat(Lgood, 1:4), ctdat(Lgood, 5), ...
    [], [], [], [], wk(Lgood));
bsm = ddExp5fz_F([fits; nan],e,wk(Lgood));
%bsm(:,1) = bsm(:,1) - fits(5);

% get binned data during dots
bins  = [(0:50:1300)', (200:50:1500)'];
nbins = size(bins,1);
[r,zs,rs] = getFIRA_rateByBin(Lgood, sid, times(Lgood,2), times(Lgood,5), [], bins);

% compute roc index for each bin, sep by chc and by bias
tax   = mean(bins./1000,2);
%ucohs = nonanunique(cohs);
%ncohs = length(ucohs);
rocs_ = nans(1, nbins, 6);

for bb = 1:nbins
    Lt1 = Lcor(Lgood) & isfinite(rs(:,bb)) & chcs(Lgood)==1;
    Lt2 = Lcor(Lgood) & isfinite(rs(:,bb)) & chcs(Lgood)==-1;

    % low coh
    Lb1 = Lt1 & cohs(Lgood)<0.2;
    Lb2 = Lt2 & cohs(Lgood)<0.2;
    if sum(Lb1)>4 && sum(Lb2)>4
        rocs_(1,bb,1,1) = rocN(rs(Lb1,bb), rs(Lb2,bb));
    end

    % high coh
    Lb1 = Lt1 & cohs(Lgood)>0.2;
    Lb2 = Lt2 & cohs(Lgood)>0.2;
    if sum(Lb1)>4 && sum(Lb2)>4
        rocs_(1,bb,2,1) = rocN(rs(Lb1,bb), rs(Lb2,bb));
    end

    % bias towards
    Lb1 = Lt1 & bsm(:,1)>0;
    Lb2 = Lt2 & bsm(:,1)<0;
    if sum(Lb1)>4 && sum(Lb2)>4
        rocs_(1,bb,3,1) = rocN(rs(Lb1,bb), rs(Lb2,bb));
    end

    % bias away
    Lb1 = Lt1 & bsm(:,1)<0;
    Lb2 = Lt2 & bsm(:,1)>0;
    if sum(Lb1)>4 && sum(Lb2)>4
        rocs_(1,bb,4,1) = rocN(rs(Lb1,bb), rs(Lb2,bb));
    end
    
    mus = fits(1).*cohs(Lt1|Lt2).^1.25./...
        fits(2).*(1 - exp(-fits(2).*tax(bb)));
    bs  = abs(bsm(Lt1|Lt2,1));
    rocs_(1,bb,5) = nanmean(bs./(mus+bs));
    rocs_(1,bb,6) = nanmean(bs)./(nanmean(mus) + nanmean(bs));
end

%if ncohs < 7
%    rocs_ = cat(3, nans(1,nbins,7-ncohs,3,2), rocs_);
%end

return

cla reset; hold on;
plot(rocs(:,1), 'k-');
plot(rocs(:,2), 'r-');

