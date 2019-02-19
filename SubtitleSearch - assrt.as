/*
	subtitle search by assrt
*/

//	string GetTitle() 													-> get title for UI
//	string GetVersion													-> get version for manage
//	string GetDesc()													-> get detail information
//	string GetLoginTitle()												-> get title for login dialog
//	string GetLoginDesc()												-> get desc for login dialog
//	string ServerCheck(string User, string Pass) 						-> server check
//	string ServerLogin(string User, string Pass) 						-> login
//	void ServerLogout() 												-> logout
//	string GetLanguages()																-> get support language
//	string SubtitleWebSearch(string MovieFileName, dictionary MovieMetaData)			-> search subtitle bu web browser
//	array<dictionary> SubtitleSearch(string MovieFileName, dictionary MovieMetaData)	-> search subtitle
//	string SubtitleDownload(string id)													-> download subtitle
//	string GetUploadFormat()															-> upload format
//	string SubtitleUpload(string MovieFileName, dictionary MovieMetaData, string SubtitleName, string SubtitleContent)	-> upload subtitle


array<array<string>> LangTable = 
{
	{ "zh", "chinese" },
	{ "en", "english" }
};

//string Token = "fqcVallCrhAfjJPsrpPJXMgt6GLqWavC";
string Token = "";
string ASSRT_API_HOST = "http://api.assrt.net";

string GetTitle()
{
	return "assrt";
}

string GetVersion()
{
	return "1";
}

string GetDesc()
{
	return "http://assrt.net";
}

string GetLanguages()
{
	string ret = "";
	
	for (int i = 0, len = LangTable.size(); i < len; i++)
	{
		if (ret.empty()) ret = LangTable[i][0];
		else ret = ret + "," + LangTable[i][0];
	}
	return ret;
}

string ServerCheck(string User, string Pass)
{
	string ret = HostUrlGetString(GetDesc());
	
	if (ret.empty()) return "fail";
	return "200 OK";
}

void AssignItem(dictionary &dst, JsonValue &in src, string dst_key, string src_key = "")
{
	if (src_key.empty()) src_key = dst_key;
	if (src[src_key].isString()) dst[dst_key] = src[src_key].asString();
	else if (src[src_key].isInt64()) dst[dst_key] = src[src_key].asInt64();	
}

string UrlComposeQuery(string &host, const string &in path, dictionary &in querys)
{
	string ret = host + path + "?";

	const array<string> keys = querys.getKeys();

	for (int i = 0, len = keys.size(); i < len; i++){
		if (i > 0 ){
			ret += "&";
		}
		ret += keys[i] + "=" + HostUrlEncode(string(querys[keys[i]]));
	}

	return ret;
}

array<dictionary> SubtitleSearch(string MovieFileName, dictionary MovieMetaData)
{
	array<dictionary> ret;
	string title = string(MovieMetaData["title"]);
	string apiSearch = UrlComposeQuery(ASSRT_API_HOST, "/v1/sub/search", {
		{"token", Token},
		{"q", title},
		{"no_muxer", formatUInt(1)}
	});

	string json = HostUrlGetString(apiSearch);
	JsonReader Reader;
	JsonValue Root;
	
	if (Reader.parse(json, Root) && Root.isObject())
	{
		if (Root["status"].isInt()){
			int status = Root["status"].asInt();

			if (status == 0) {
				JsonValue subs = Root["sub"]["subs"];

				if (subs.isArray()){
					for(int i = 0, len = subs.size(); i < len; i++){
						dictionary item;
						AssignItem(item, subs[i], "id");
						AssignItem(item, subs[i], "title", "native_name");
						AssignItem(item, subs[i], "fileName", "videoname");
						AssignItem(item, subs[i], "format", "subtype");
						item["lang"] = "zh";
						ret.insertLast(item);
					}
				}
			}
		}
	}
	
	return ret;
}

string SubtitleDownload(string download)
{
	string apiDetail = UrlComposeQuery(ASSRT_API_HOST, "/v1/sub/detail", {
		{"token", Token},
		{"id", download}
	});

	string json = HostUrlGetString(apiDetail);
	JsonReader Reader;
	JsonValue Root;
	
	if (Reader.parse(json, Root) && Root.isObject())
	{
		if (Root["status"].isInt()){
			int status = Root["status"].asInt();

			if (status == 0) {
				JsonValue subs = Root["sub"]["subs"];				

				if (subs.isArray()){
					JsonValue subDetail = subs[0];

					if (subDetail.isObject()){

						JsonValue url = subDetail["url"];
													
						if (url.isString())
						{
							return HostUrlGetString(url.asString());
						}
					}					
				}
			}
		}
	}

	return "";
}
