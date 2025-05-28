package;

import cpp.abi.Abi;
import flixel.FlxSprite;
import flixel.FlxState;
import haxe.Http;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.*;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class PlayState extends FlxState
{
	var token:String = "Bearer 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";
	var path:String = '';
	var cur_ver:String;
	var updated:Bool = true;

	override public function create()
	{
		super.create();
		var spr:FlxSprite = new FlxSprite().makeGraphic(500, 500, 0xff5c3964);
		add(spr);
		checkForUpdates();
	}

	public function checkForUpdates() {
		var curVersion = File.getContent("update.txt");
		path = FileSystem.absolutePath('');

		var http:Http = new Http("https://api.github.com/repos/Cherif107/testing-auto-upd");
		http.setHeader("User-Agent", "asparagus");
		http.onData = (data:String) ->
		{
			cur_ver = Json.parse(data).pushed_at;
			updated = curVersion == cur_ver;
			if (!updated)
			{
				// updateSelf();
				updateExport(curVersion);
			}
		}
		http.request();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function updateSelf()
	{
		// var repo:Http = new Http("https://github.com/Cherif107/testing-auto-upd/archive/refs/heads/main.zip");
		// repo.setHeader("User-Agent", "asparagus");
		// repo.onStatus = (msg:Int) -> {
		// 	var download:Http = new Http(repo.responseHeaders.get("Location"));
		// 	download.onBytes = (data:haxe.io.Bytes) -> {
		// 		var entries:List<Entry> = Reader(BytesInput(data));

		// 	}
		// 	download.request();
		// }
		// repo.request();
	}

	public function updateExport(date:String)
	{
		var actions_list:Http = new Http("https://api.github.com/repos/Cherif107/testing-auto-upd/actions/runs?status=completed&per_page=1");
		actions_list.setHeader("User-Agent", "asparagus");
		actions_list.onData = (data:String) ->
		{
			var artf = Json.parse(data).workflow_runs[0];
			if (artf.updated_at == date)
				return;

			var recent_artifact:Http = new Http(artf.artifacts_url);
			recent_artifact.setHeader("User-Agent", "asparagus");
			recent_artifact.onData = (data:String) ->
			{
				var artifact_archive:Http = new Http(Json.parse(data).artifacts[0].archive_download_url);
				artifact_archive.setHeader("User-Agent", "asparagus");
				artifact_archive.setHeader("Authorization", token);
				artifact_archive.onStatus = (msg:Int) ->
				{
					var artifact_download:Http = new Http(artifact_archive.responseHeaders.get("Location"));
					artifact_download.onBytes = (data:Bytes) ->
					{
						var entries:List<Entry> = Reader.readZip(new BytesInput(data));
						unzip(entries, path);
						File.saveContent('update.txt', cur_ver);
						Sys.exit(0);
					}
					artifact_download.request();
				}
				artifact_archive.request();
			}
			recent_artifact.request();
		}
		actions_list.request();
	}

	public static function unzip(_entries:List<Entry>, _dest:String, ignoreRootFolder:String = "" ) {
        for(_entry in _entries) {
            
            var fileName = _entry.fileName;
            if (fileName.charAt (0) != "/" && fileName.charAt (0) != "\\" && fileName.split ("..").length <= 1) {
                var dirs = ~/[\/\\]/g.split(fileName);
                if ((ignoreRootFolder != "" && dirs.length > 1) || ignoreRootFolder == "") {
                    if (ignoreRootFolder != "") {
                        dirs.shift ();
                    }
                
                    var path = "";
                    var file = dirs.pop();
                    for( d in dirs ) {
                        path += d;
                        FileSystem.createDirectory(_dest + "/" + path);
                        path += "/";
                    }
                
                    if( file == "" ) {
                        continue; // was just a directory
                    }
                    path += file;
                
                    var data = haxe.zip.Reader.unzip(_entry);
                    var f = File.write (_dest + "/" + path, true);
                    f.write(data);
                    f.close();
                }
            }
        } //_entry

        Sys.println('');
        Sys.println('unzipped successfully to ${_dest}');
    } //unzip
}
