@echo off
:: 
:: Run this file to reconstruct using psftof
:: 

setlocal

set cmd= C:\Siemens\PET\bin.win64-VG60\e7_recon 

set cmd= %cmd% --tof 
set cmd= %cmd% --mash4 
set cmd= %cmd% --algo op-osem
set cmd= %cmd% --is 2,21
set cmd= %cmd% --psf 
set cmd= %cmd% -u 0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-LM-WB-umap.mhdr,0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-LM-WB-umapBedRemoval.mhdr
set cmd= %cmd% -n ..\0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-norm.n.hdr
set cmd= %cmd% --offs -1.783,0.63,-754.143,-0.004,-0.038,-0.61
set cmd= %cmd% --gf 
set cmd= %cmd% --quant 1
set cmd= %cmd% -w 400
set cmd= %cmd% --ctm -859.5,1120.5,2,2 
set cmd= %cmd% --ol
set cmd= %cmd% --fltr GAUSSIAN,2,2
set cmd= %cmd% -l 73,.
set cmd= %cmd% --fl 
set cmd= %cmd% --ecf 
set cmd= %cmd% --izoom 1
set cmd= %cmd% --cvrg 97 
set cmd= %cmd% -e C:\Users\pet\Desktop\Rb82\paediatric_fdg\0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-Converted\0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-LM-WB\0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-LM-WB-sino.mhdr
set cmd= %cmd% --oi 0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-LM-WB-PSFTOF.mhdr
set cmd= %cmd% --dcr 1609837764
pushd "C:\Users\pet\Desktop\Rb82\paediatric_fdg\0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-Converted\0630c6a2-1fd6-4d4e-bfaf-93a9d6fed142_10-LM-WB"

%cmd% --mat (0,0,0) --app
%cmd% --mat (1,0,0) --app
%cmd% --mat (2,0,0) --app
%cmd% --mat (3,0,0) --app
%cmd% --mat (4,0,0) --app
%cmd% --mat (5,0,0) --app
%cmd% --mat (6,0,0) --app
%cmd% --mat (7,0,0) --app
%cmd% --mat (8,0,0) --app
%cmd% --mat (9,0,0) --app
%cmd% --mat (10,0,0) --app
%cmd% --mat (11,0,0) --app
%cmd% --mat (12,0,0) --app
%cmd% --mat (13,0,0) --app
%cmd% --mat (14,0,0) --app


popd


endlocal
