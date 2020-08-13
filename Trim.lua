--[[

]]

script_name = "Trim"
script_description = "Trims audio/video related to the selected lines"
script_author = "Sam1367 & SSgumS (edited unanimated's encode script)"
script_version = "1.0.0"

function trim(sub,sel,act)
	ADD=aegisub.dialog.display
	ADP=aegisub.decode_path
	ADO=aegisub.dialog.open
	ak=aegisub.cancel
	trimconfig=ADP("?user").."\\trim.conf"
	scriptpath=ADP("?script").."\\"
	scriptname=aegisub.file_name()
	vpath=ADP("?video").."\\"
	ms2fr=aegisub.frame_from_ms
	fr2ms=aegisub.ms_from_frame
	sframe0=999999
	eframe0=0
	videoname=nil
	wvideo=false
	ffconf="-vn -c:a copy -movflags +faststart"
	ffpath="C:\\Program Files\\FFmpeg\\bin\\ffmpeg.exe"
	
	file=io.open(trimconfig)
    if file~=nil then
		konf=file:read("*all")
		io.close(file)
		ffpath=konf:match("ffpath:(.-)\n")
	end
	
    for i=1,#sub do
		if sub[i].class=="info" then
			if sub[i].key=="Video File" then videoname=sub[i].value break end
		end
		if sub[i].class~="info" then break end
	end
	
    if videoname==nil then videoname=aegisub.project_properties().video_file:gsub("^.*\\","") end
    if videoname==nil or videoname=="" or aegisub.frame_from_ms(10)==nil then t_error("No video detected.",1) end
    vid2=videoname:gsub("%.[^%.]+","") :gsub("_?premux","") :gsub("_?workraw","")
    vid2=vid2.."_trimmed"
	
	acbuttons={"Trim (Audio Only)","Audio Only with Encode","Audio+Video with Encode","Cancel"}
	aebuttons={"Trim (Audio Only with Encode)","Audio Only","Audio+Video with Encode","Cancel"}
	avcbuttons={"Trim (Audio+Video)","Audio+Video with Encode","Audio Only","Cancel"}
	avebuttons={"Trim (Audio+Video with Encode)","Audio+Video","Audio Only","Cancel"}
	button_ids={cancel="Cancel"}
	GUI = {
		{x=0,y=0,class="label",label="FFmpeg path:"},
		{x=1,y=0,width=25,class="edit",name="ffpath",value=ffpath},
		{x=0,y=1,class="label",label="FFmpeg params:"},
		{x=1,y=1,width=25,class="edit",name="ffconf",value=ffconf},
	}

	repeat
		wvideo=false
		buttons = acbuttons
		gui("ffconf","-vn -c:a copy -movflags +faststart")

		if pressed=="Audio Only with Encode" then
			wvideo=false
			buttons = aebuttons
			gui("ffconf","-vn -c:a aac -b:a 64k -movflags +faststart")
		elseif pressed=="Audio+Video with Encode" then
			wvideo=true
			buttons = avebuttons
			gui("ffconf","-preset veryslow -crf 30 -tune animation -x264-params level=42:ref=6 -pix_fmt yuv420p -profile:v high -vf scale=-2:720 -movflags +faststart")
		elseif pressed=="Audio+Video" then
			t_error("It's recommended to use \"Audio+Video with Encode\" mode for accurate trimming on \"Audio+Video\".",false)
			wvideo=true
			buttons = avcbuttons
			gui("ffconf","-c copy -movflags +faststart")
		end
		
		button_ids.ok = buttons[1]
		pressed, res = ADD(GUI,buttons,button_ids)
	until pressed==buttons[1] or not pressed

	if not pressed then
		ak()
	end
	
	konf="ffpath:"..res.ffpath.."\n"
	file=io.open(trimconfig,"w")
	file:write(konf)
	file:close()
    ----------------------------------------------------------------------------------------------------------------------------------------
	
	ffpath=res.ffpath
	ffconf=res.ffconf
	wvideo=res.wvideo
    target=scriptpath
	vfull=vpath..videoname
	
	if wvideo then
		extension="mp4"
	else
		extension="m4a"
	end
    
	file=io.open(ffpath)
	if file==nil then t_error(ffpath.."\nERROR: File does not exist (x264).",true) else file:close() end
	file=io.open(vfull)
	if file==nil then t_error(vfull.."\nERROR: File does not exist (video source).",true) else file:close() end
    
    -- Trim
	for si,li in ipairs(sel) do
		line = sub[li]
		
		start=line.start_time
		endt=line.end_time
		sframe=ms2fr(start)
		eframe=ms2fr(endt)
		
		resfilename=vid2
		resfilename=resfilename.."_"..sframe.."-"..eframe
		
		timec1=time2string(start)
		timec2=time2string(endt-start)
		resultfile=target..resfilename.."."..extension
		command="\""..ffpath.."\" -ss "..timec1.." -i \""..vfull.."\" -t "..timec2.." "..ffconf.." \""..resultfile.."\""
		
		-- Batch Script
		batch=scriptpath.."trim.bat"
		
		local xfile=io.open(batch,"w")
		xfile:write(command)
		xfile:close()
		
		-- Execute
		batch=batch:gsub("%=","^=")
		os.execute(quo(batch))
	end
end

function gui(a,b)
	if b==nil then b="" end
	for k,v in ipairs(GUI) do
		if v.name==a then v.value=b elseif res~=nil then v.value=res[v.name] end
	end
end

function time2string(num)
	timecode=math.floor(num/1000)
	tc0=math.floor(timecode/3600)
	tc1=math.floor(timecode/60)
	tc2=timecode%60
	numstr="00"..num
	tc3=numstr:match("(%d%d)%d$")
	if tc1==60 then tc1=0 tc0=tc0+1 end
	if tc2==60 then tc2=0 tc1=tc1+1 end
	if tc1<10 then tc1="0"..tc1 end
	if tc2<10 then tc2="0"..tc2 end
	tc0=tostring(tc0)
	tc1=tostring(tc1)
	tc2=tostring(tc2)
	timestring=tc0..":"..tc1..":"..tc2.."."..tc3
	return timestring
end

function quo(x) x="\""..x.."\"" return x end

function t_error(message,cancel)
	ADD({{class="label",label=message}},{"OK"},{close='OK'})
	if cancel then ak() end
end

aegisub.register_macro(script_name,script_description,trim)
