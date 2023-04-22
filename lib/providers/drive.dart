import 'dart:io';
import 'dart:typed_data';

import 'package:crs_manager/providers/database.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/drive_auth.dart';
import '../utils/exceptions.dart';

class DriveHandler {
  final dio = Dio(
    BaseOptions(
      receiveDataWhenStatusError: true,
      validateStatus: (status) => true,
    ),
  );

  Token token = Token(
    accessToken: "",
    expiresIn: 0,
  );
  String parentFolderId = "";
  Map<String, dynamic> secrets;

  DriveHandler({required this.secrets});

  Future<void> init() async {
    await refreshToken();

    var parentFolder = await fileExists("CRS-Manager");
    // If parent folder is not found, create it
    parentFolder ??= await createFile(
        "CRS-Manager", "application/vnd.google-apps.folder", "");
    parentFolderId = parentFolder.id;
  }

  Future<Token> refreshToken() async {
    String url = "https://oauth2.googleapis.com/token";
    final queryParameters = {
      "client_id": secrets["client_id"],
      "client_secret": secrets["client_secret"],
      "grant_type": "refresh_token",
      "refresh_token": secrets["refresh_token"],
    };

    final response = await dio.post(
      url,
      queryParameters: queryParameters,
    );

    // Invalid refresh token
    if ([400, 401].contains(response.statusCode)) {
      throw BadSecretsError();
    }

    if (response.statusCode != 200) {
      throw UnknownDriveError();
    }

    // Set expiry to 60 seconds less than actual expiry
    token = Token(
      accessToken: response.data["access_token"],
      expiresIn: response.data["expires_in"] - 60,
    );

    return token;
  }

  Future<DriveFile?> fileExists(String name) async {
    String url = "https://www.googleapis.com/drive/v3/files";
    final queryParameters = {
      "q": "name = '{$name}' and trashed=false",
      "fields": "files(id, name, mimeType, parents, kind)",
    };

    var results = await dio.get(
      url,
      queryParameters: queryParameters,
      options: Options(headers: {
        "Authorization": "Bearer ${token.accessToken}",
      }),
    );

    // Invalid access token
    if (results.statusCode == 401) {
      await refreshToken();
      return fileExists(name);
    }

    if (results.statusCode != 200) {
      throw UnknownDriveError();
    }

    if (results.data["files"].length > 0) {
      return DriveFile.fromMap(results.data["files"][0]);
    }

    return null;
  }

  Future<DriveFile> createFile(
      String name, String mimeType, String parent) async {
    String url = "https://www.googleapis.com/drive/v3/files";
    final data = {
      "name": name,
      "mimeType": mimeType,
      if (parent.isNotEmpty) "parents": [parent],
    };

    var result = await dio.post(
      url,
      data: data,
      options: Options(
        headers: {
          "Authorization": "Bearer ${token.accessToken}",
        },
      ),
    );

    // Invalid access token
    if (result.statusCode == 401) {
      await refreshToken();
      return createFile(name, mimeType, parent);
    }

    if (result.statusCode != 200) {
      throw UnknownDriveError();
    }

    return DriveFile.fromMap(result.data);
  }

  Future<DriveFile> uploadFile(String fileId, Object data) async {
    String url =
        "https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media";

    var result = await dio.patch(
      url,
      data: data,
      options: Options(
        headers: {
          "Authorization": "Bearer ${token.accessToken}",
        },
      ),
    );

    // Invalid access token
    if (result.statusCode == 401) {
      await refreshToken();
      return uploadFile(fileId, data);
    }

    if (result.statusCode != 200) {
      throw UnknownDriveError();
    }

    return DriveFile.fromMap(result.data);
  }

  Future<File> downloadFile(String fileId) async {
    String url = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media";
    var savePath = (await getTemporaryDirectory()).path + "/$fileId";

    var result = await dio.download(url, savePath);

    // Invalid access token
    if (result.statusCode == 401) {
      await refreshToken();
      return downloadFile(fileId);
    }

    if (result.statusCode != 200) {
      throw UnknownDriveError();
    }

    return File(savePath);
  }

  Future<DriveFile> uploadChallanImage(Uint8List bytes, String fileName) async {
    var challanFile = await fileExists(fileName);
    // If challan file is not found, create it
    challanFile ??= await createFile(fileName, "image/jpeg", parentFolderId);

    return uploadFile(challanFile.id, bytes);
  }
}
