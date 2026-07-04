# tactiq.io free youtube transcript

# Make a web build of your Odin + Raylib game

# https://www.youtube.com/watch/WhRIjmHS-Og

00:00:00.120 hello everyone let's look at how to take
00:00:02.639 some old code I have here from my snake
00:00:05.080 tutorial video and make it work on the
00:00:07.720 web so there's this whole 90 minute
00:00:09.920 tutorial where where I show how to make
00:00:12.040 a snake game and it's for total oldin
00:00:14.799 beginners will take that and make it
00:00:18.160 runable inside a web browser and we will
00:00:20.880 do that using another repository have
00:00:22.880 and this snake tutorial code repository
00:00:25.119 is linked in the description of this
00:00:27.000 video and we will be using this uh
00:00:29.359 Repository for the web stuff this Odin
00:00:32.439 ra web repository is a template for
00:00:36.320 making games that work both on the
00:00:39.440 browser and on the desktop and there's a
00:00:41.960 little demo here a live demo you can
00:00:43.680 click and you see it's just like a thing
00:00:46.960 funny round cat following the cursor and
00:00:48.920 there's some Ray gooey buttons here and
00:00:50.680 stuff there are some requirements in
00:00:52.520 order to use this template one is of
00:00:54.280 course that you have the Odin compiler
00:00:55.840 installed but the the big requirement is
00:00:58.519 that you have M script and installed m
00:01:00.640 scripton is required by rib when running
00:01:02.920 on the web so that it for example can
00:01:05.400 turn openg G calls into webg calls it's
00:01:08.159 sort of a translation layer in between
00:01:11.280 and there's a link here for how to
00:01:13.080 install it so if you click this link
00:01:16.080 then you just need to do the stuff under
00:01:17.920 installation instruction using emdk so
00:01:20.360 you just do this stuff and then you go
00:01:22.759 down here and you do this stuff as well
00:01:25.240 and then you are done and uh when you've
00:01:28.040 done that you can clone both the
00:01:29.960 repositories the snake tutorial
00:01:31.600 repository and the Odin rib web
00:01:35.040 repository inside the Odin ra web
00:01:38.079 repository there are a couple of
00:01:39.399 different uh scripts uh we will be using
00:01:42.720 this build web batch file here or the sh
00:01:46.439 file if you are on Linux or Mac the only
00:01:49.640 thing you need to do in order to sort of
00:01:51.600 configure this is that you need to open
00:01:53.640 this and inside this build web you need
00:01:57.600 to point out the M script and SD K
00:02:00.719 directory where you put them script them
00:02:02.719 when you installed it if you are on Mac
00:02:04.799 or Linux and you install them script
00:02:06.600 them through some kind of package
00:02:07.600 manager then you might be able to skip
00:02:09.119 this step of course then you would also
00:02:10.399 be using the build web. sh file not the
00:02:13.080 batch file but there is a similar uh
00:02:16.480 configuration uh variable inside that
00:02:19.599 script but you might be able to skip
00:02:21.480 setting it because it might already be M
00:02:24.319 script might already be in your path so
00:02:26.640 once you have that set up then you can
00:02:28.319 test the Odin ra web temp PL so you can
00:02:30.519 navigate there in a command prompt and
00:02:32.400 you can type build web and it will run a
00:02:35.599 bit and then it will say some stuff and
00:02:38.000 eventually it will say web build create
00:02:39.640 in build SL web and we can see here in
00:02:42.400 the file explorer that we have the build
00:02:44.040 folder here and then the web folder and
00:02:45.800 then you have these different files in
00:02:47.760 here now on most system you won't be
00:02:49.840 able to just run index. HTML because
00:02:52.239 there will be some JavaScript errors due
00:02:54.400 to it wanting to open several separate
00:02:57.760 files and it can only do that if those
00:02:59.319 come from like the same web server or
00:03:01.239 something like that it's called a course
00:03:03.360 error so you can go into build SL web
00:03:06.440 and if you have python installed then
00:03:07.799 you can do python DM HTTP do server this
00:03:10.440 will run a small web server that serves
00:03:13.480 the stuff in this folder so if you do
00:03:15.680 that and it says it's serving HTP import
00:03:17.640 8,000 so if you go to
00:03:20.360 that address Local Host this is your own
00:03:23.480 computer Local Host 8,000 then you see
00:03:26.400 now we're running the local version of
00:03:28.480 that example I showed earlier so now we
00:03:31.319 have something that we can change and
00:03:32.760 put our snake game into so we will sort
00:03:35.840 of copy the Snake Game stuff into this
00:03:39.360 repository in order to make it build on
00:03:41.319 the web now let's look at the snake code
00:03:43.360 we have downloaded so inside a snake
00:03:45.200 tutorial code folder we have these
00:03:46.840 things the main interesting things is
00:03:49.159 the snake. Odin file which contains the
00:03:51.360 whole game we can first try running this
00:03:53.879 uh we can open a command prompt and do
00:03:55.519 oldin run Dot and you will see that this
00:03:58.680 is the snake
00:04:00.239 this is the end result of the tutorial
00:04:02.480 video so let's open the snake code uh we
00:04:06.079 pull it into the into here into the side
00:04:08.959 here and here's our snake code this is
00:04:11.319 the code we need to bring into the
00:04:12.519 template and then in the template we
00:04:14.159 have a couple of different files so if
00:04:15.560 you open the source folder you have like
00:04:17.358 these are the main entry points for the
00:04:19.560 desktop and Web Bar in here uh but the
00:04:22.720 game itself is in here if you compare
00:04:26.400 this to the web template here then here
00:04:30.120 we see we have some kind of init proc
00:04:31.680 and an update proc so we don't have a
00:04:34.720 main procedure like this uh with a with
00:04:37.880 a loop instead sort of the content of
00:04:40.280 the loop should go into update and the
00:04:43.800 setup that's before the loop should go
00:04:46.280 into in
00:04:47.479 it and this is because the web browser
00:04:50.560 will first initialize things and then it
00:04:53.800 will request sort of Animation frames
00:04:56.280 it's called which means that it will
00:04:57.880 whenever it uh needs to redraw it will
00:05:00.720 call the the update proc here
00:05:04.639 and that's just because you can't have a
00:05:07.560 a loop in a web browser that just runs
00:05:10.199 forever because then the other part of
00:05:11.720 the web browser would would lock up
00:05:14.039 essentially so the web browser must ask
00:05:16.360 the game itself when when it when when
00:05:18.360 is the right time for it to do so in
00:05:20.919 order to update it so that's why it's
00:05:22.400 split up in web
00:05:24.000 browser so let's just try moving all the
00:05:26.319 snake stuff to over here so first I will
00:05:28.319 remove everything that's not needed I
00:05:29.800 will just delete this I will keep the
00:05:31.120 Run flag these texture things are just
00:05:33.759 the example textures used and I will
00:05:35.560 delete all this
00:05:37.520 stuff and this stuff I can keep probably
00:05:41.759 well we can delete that stuff as well um
00:05:45.039 we can put these stuff at the bottom
00:05:46.720 like that so these are our free things
00:05:49.039 you see now it's pretty nice and clean
00:05:50.520 like that and then I will just take
00:05:52.000 these things that's before the main Loop
00:05:53.600 and put them into
00:05:55.560 here like
00:05:57.759 that and then I will go in into the main
00:06:00.479 Loop the contents of it select
00:06:02.960 everything go to down here and put that
00:06:06.400 into
00:06:07.960 update just paste it in and then I fixed
00:06:10.560 the indentation a bit and then these
00:06:12.960 things happen after the loop so that's
00:06:14.479 sort of a shutdown thing so then we go
00:06:16.599 down to shut down here and we run
00:06:21.160 that okay on top of that there are some
00:06:23.400 Global variables here these guys we need
00:06:25.680 to copy these as well so we take those
00:06:28.080 and we put them just here
00:06:30.199 uh this run thing maybe we can put here
00:06:33.039 so if we now go back to a command prompt
00:06:35.120 that looks at the Odin rib web
00:06:37.360 repository and we run build web then
00:06:39.800 there might be some errors I will switch
00:06:42.000 back to the sublime and just build from
00:06:45.319 in there instead I I have the I have a
00:06:47.800 build system set up so I can I can do
00:06:49.919 that there's a Sublime project file but
00:06:52.160 that does the same thing as the command
00:06:53.960 prom I just want to show that that they
00:06:55.639 do the same thing so there seems to be
00:06:57.639 one error here
00:07:00.360 this is just because I compile with
00:07:03.080 different uh vetting rules and then it
00:07:06.599 complains about lots of different things
00:07:08.160 oh i' I've forgotten to copy all these
00:07:10.120 procedures as well the restart and place
00:07:12.879 food procedures so we'll put those in as
00:07:15.199 well we can put them ah just here maybe
00:07:18.400 like
00:07:19.879 that and then we'll compile again so we
00:07:22.440 just compile and see what we need fixing
00:07:24.400 okay it didn't like that import because
00:07:26.039 it was unnecessary and now it complains
00:07:28.360 that these things are not defined and
00:07:31.199 well they're not used rather and we can
00:07:33.919 see a problem here that food Sprite is
00:07:35.599 just defined as a local variable because
00:07:37.599 it's colon equal so this is a local
00:07:39.479 variable in this scope but it's not used
00:07:42.000 in the old code it was sort of before
00:07:44.960 the loop and then the loop you know
00:07:46.720 could see all those variables so we
00:07:48.199 can't do like that anymore maybe in this
00:07:51.240 case you could put everything inside a
00:07:52.639 big struct that's some kind of state
00:07:54.159 struct but in my case I will select
00:07:56.159 these and move them into Global
00:07:57.240 variables so that the init procedure can
00:07:59.159 set them and then the update procedure
00:08:00.879 can can use them so I will Multi select
00:08:03.400 all these and then I will step back two
00:08:06.080 steps copy this move up
00:08:10.919 here and do like that and these are
00:08:13.919 sprite so these are RL texture 2D and
00:08:18.560 these are probably
00:08:20.879 RL RL do sound and this guy is RL sound
00:08:26.360 to and then of course this thing here
00:08:29.280 the finds a new variable if you just do
00:08:30.879 equals you set the value of an existing
00:08:32.839 variable so we just want to set that one
00:08:34.679 if we now compile then there is still
00:08:37.200 some error okay there's some imports
00:08:38.919 missing so we go to the top here we can
00:08:41.479 we can actually compare these two the
00:08:44.320 the only thing I'm missing here is
00:08:46.240 probably the the math Library so in the
00:08:48.200 snake code we have math here so we copy
00:08:50.720 that in we compile it and there you see
00:08:53.920 it says web build created I still have
00:08:57.600 the web browser running here so I can
00:08:59.000 just open the web browser again and go
00:09:01.240 to Local Host
00:09:03.920 8,000 and see what
00:09:06.600 happens it something seems to be wrong
00:09:08.760 it just says the game is obviously
00:09:10.480 running but it's just game over over and
00:09:12.240 over what is missing is that I haven't
00:09:15.279 actually copied over the graphics yet uh
00:09:17.800 so the game is able to run without the
00:09:19.640 graphics it's probably just textures
00:09:22.079 without anything in them so I've opened
00:09:23.920 the file explorer here again and what we
00:09:26.000 need to do is in the Odin ra web folder
00:09:29.480 is an assets folder here and that
00:09:31.320 currently contains these two cat
00:09:32.720 textures that you saw in the little demo
00:09:35.600 file in the little demo game so we can
00:09:37.680 delete those two and then we just need
00:09:39.000 to copy the four things essentially we
00:09:40.920 need to copy you know these four things
00:09:44.279 here and that's the the PNG files here
00:09:48.360 four PNG files and two sounds and we
00:09:50.600 copy those into the assets folder and
00:09:53.640 the thing about the assets folder is
00:09:55.000 that if you look inside build the build
00:09:56.959 web then then you can see here on on
00:09:58.880 this line here that it says preload file
00:10:01.440 assets what this does is that when the M
00:10:05.640 script and stuff runs then it can take
00:10:07.720 the assets it takes the assets folder
00:10:09.760 and sort of put puts it into the the the
00:10:12.959 web build so that you have access to all
00:10:15.320 those things so anything inside assets
00:10:16.800 folder you have access to when your web
00:10:20.640 game is working and also if you do use
00:10:22.880 the do the desktop uh build that assets
00:10:25.680 folder is copied to wherever you do your
00:10:27.560 build so you can also use those things
00:10:30.320 the only thing we need to change here is
00:10:31.959 that you must now say Assets in front
00:10:34.440 here um like this maybe you could make a
00:10:37.519 little procedure that Returns the
00:10:40.120 correct name or something I don't know
00:10:42.519 but we can do like that and now if we
00:10:45.279 recompile this like that and we switch
00:10:47.639 back to web browser and play and now
00:10:50.120 we're playing our game in a web
00:10:54.680 browser you can also make a desktop
00:10:57.480 build of your game so if you're in the
00:10:59.600 command prompt inside the Odin RB web
00:11:01.560 folder here again and run build
00:11:04.800 desktop then it says build back/ desktop
00:11:08.519 uh what the build was created in build
00:11:10.440 back/ desktop and if you go into the
00:11:12.639 file explorer and you go into build
00:11:14.519 desktop then here is your
00:11:17.000 game and if you run that then you can
00:11:19.240 play the game and it uses the same code
00:11:21.279 as the web build this means that you can
00:11:23.160 work on the desktop build and the web
00:11:25.320 build uh side by side kind of and I
00:11:28.720 would probably work mostly on the
00:11:30.240 desktop build because it's easier to
00:11:31.760 debug and stuff and then you can
00:11:33.680 whenever you want to you can check if
00:11:35.800 your web build still works by running
00:11:37.760 the build web script so that's mostly it
00:11:40.760 if you want to know more about how this
00:11:42.360 Oden R web stuff works then you can look
00:11:46.480 inside that repository in the read me
00:11:50.000 there is lots of information about how
00:11:53.279 how it all works you can also look in
00:11:54.720 the build script there's also some index
00:11:58.320 uh template h HTML file that you can
00:12:00.440 look into inside that repository that
00:12:02.880 shows how things are uh set up how how
00:12:06.160 the JavaScript is set up and stuff so
00:12:09.320 you can look into that and finally I
00:12:11.240 also just want to say that I have also
00:12:13.720 put
00:12:14.920 this web build scripts into my Odin
00:12:18.440 raiload template so if you with this
00:12:22.399 template you can build your games on the
00:12:24.279 desktop with hot load and then when you
00:12:26.480 want to make a web build the the script
00:12:28.519 is already there so this repository here
00:12:31.800 which is also linked in the video
00:12:33.160 description is does mostly the same
00:12:35.399 stuff as the the Odin really web
00:12:38.240 repository but it does way more which is
00:12:40.920 why I I don't show this in this video uh
00:12:43.399 because it will be too many different
00:12:45.440 things at once but with this one you can
00:12:47.519 do hot reloading and then make a web
00:12:51.240 build as well when you feel like it but
00:12:54.120 the web Builder does not have hot
00:12:55.560 reloading it's just for making a sort of
00:12:56.880 a release build that works on the web a
00:13:00.480 final thing you might have noticed here
00:13:02.160 is that this thing doesn't really scale
00:13:05.639 to the web browser that's quite easy to
00:13:08.880 fix uh there is a thing here that is run
00:13:11.720 whenever the window changes size the
00:13:14.120 only thing you need to do is to change
00:13:17.240 use the screen height or something here
00:13:19.880 on the camera inside the snake game and
00:13:22.600 then you probably need to
00:13:25.440 set the window flag at the resis where
00:13:29.279 if it's called window uncore resizable
00:13:32.199 this flag so if you do those two things
00:13:34.000 you put the get screen RL get screen
00:13:36.160 height on the camera and this stuff then
00:13:38.519 you might get something that adapts to
00:13:40.800 the
00:13:41.560 screen uh to to the window height of the
00:13:44.560 of the browser there might be some
00:13:46.040 additional issues that you need to work
00:13:47.320 a bit with but that's that's the basics
00:13:49.199 of how you do that thank you so much for
00:13:51.880 watching and special thanks to my
00:13:53.560 patrons who support me and if you want
00:13:56.440 to learn more about the Odin programming
00:13:58.800 language which then I have written a
00:14:00.560 book about it so you can go to Odin
00:14:02.800 book.com and read a sample of my book
00:14:06.320 understanding the Odin programming
00:14:08.240 language and then there is also some
00:14:10.440 links there to where you can buy it in
00:14:12.560 different
00:14:13.680 formats have a great day happy
00:14:16.079 programming and bye-bye
