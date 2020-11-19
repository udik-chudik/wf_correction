% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  
%  Copyright (C) 2018 HOLOEYE Photonics AG. All rights reserved.
%  Contact: https://holoeye.com/contact/
%  
%  This file is part of HOLOEYE SLM Display SDK.
%  
%  You may use this file under the terms and conditions of the
%  "HOLOEYE SLM Display SDK Standard License v1.0" license agreement.
%  
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% This code adds the HOLOEYE SLM Display SDK installation path to MATLAB's (Octave's) search path.
% 
% You can make the addpath command persistent by running the appropriate addpath command and then running
% savepath();
% with administrative privileges.
% 
% With a persistently added SDK path, you will be able to access the HOLOEYE SLM Display SDK functions directly in the 
% command line window of MATLAB/Octave without adding the path manually after starting MATLAB/Octave. 
% You can then write scripts without calling this script at the beginning of each of your scripts which 
% needs access to the HOLOEYE SDK.
% 
% With the command 
% path
% you can inspect the content of the current MATLAB's (Octave's) search path at any time. See the MATLAB (Octave)
% documentation.
% 
% Please make sure that the mex files inside the added folder are properly compiled.
% Under MATLAB, the mexw64 files are shipped with the installer, so there is no need to recompile anything on the win64 platform.
% When using MATLAB in the 32-bit version, you will need to compile these mex files. To do this, you need to install an appropriate 
% compiler. See MATLAB documentation about supported compilers.
% For Octave, the mex files are generated for the selected Octave installation during the SDK installation process.
% If you want to use the SDK from another Octave version on your computer, you need to recompile these mex files.
% 
% MEX file compilation can be done by running the script
% heds_build_sdk_mex_files
% which is installed into the win64 and win32 folders.
% 
% There is also a script to remove the permanently added HOLOEYE SDK paths from the MATLAB (Octave) search path automatically:
% heds_build_sdk_remove_paths
% Read environment variable:
if (exist ('OCTAVE_VERSION', 'builtin') > 0)
  heds_path = getenv('HEDS_OCTAVE');
  
  % Determine bitness:
  if strcmp(getfield(uname(), 'machine'), 'x86_64') == 1
    heds_path = [heds_path, '\win64'];
  else
    heds_path = [heds_path, '\win32'];
  end
  
else
  heds_path = [getenv('HEDS_MATLAB'), '\win64'];
end
% Figure out if heds_path could be found and if yes, add to MATLAB (Octave) path:
if (exist (heds_path, 'dir')) == 7
  addpath(heds_path);
else
  fprintf(2, '\nError: Could not find HOLOEYE SLM Display SDK installation path from environment variable. \n\nPlease relogin your Windows user account and try again. \nIf that does not help, please reinstall the SDK and then relogin your user account and try again. \nA simple restart of the computer might fix the problem, too.\n');
  return;
end
%savepath();