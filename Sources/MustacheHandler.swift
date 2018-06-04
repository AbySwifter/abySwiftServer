//
//  MustacheHandler.swift
//  COpenSSL
//
//  Created by aby on 2018/6/4.
//
import PerfectLib
import PerfectHTTP
import PerfectMustache

struct UploadHandler: MustachePageHandler {
    
    func extendValuesForResponse(context contxt: MustacheWebEvaluationContext, collector: MustacheEvaluationOutputCollector) {
        #if DEBUG
        print("UploadHandler got request")
        #endif
        var values = MustacheEvaluationContext.MapType()
        // Grab the WebRequest so we can get information about what was uploaded
        let request = contxt.webRequest
        
        // create uploads dir to store files
        let fileDir = Dir(Dir.workingDir.path + "files") // 存储的文件路径
        do {
            try fileDir.create()
        } catch {
            print(error)
        }
        // Grab the fileUploads array and see what's there
        // If this POST was not multi-part, then this array will be empty
        
        if let uploads = request.postFileUploads, uploads.count > 0 {
            // Create an array of dictionaries which will show what was uploaded
            // This array will be used in the corresponding mustache template
            var ary = [[String:Any]]()
            
            for upload in uploads {
                ary.append([
                    "fieldName": upload.fieldName,
                    "contentType": upload.contentType,
                    "fileName": upload.fileName,
                    "fileSize": upload.fileSize,
                    "tmpFileName": upload.tmpFileName
                    ])
                
                // move file to webroot
                let thisFile = File(upload.tmpFileName)
                do {
                    let _ = try thisFile.moveTo(path: fileDir.path + upload.fileName, overWrite: true)
                } catch {
                    print(error)
                }
                
            }
            values["files"] = ary
            values["count"] = ary.count
        }
        
        // Grab the regular form parameters
        let params = request.params()
        if params.count > 0 {
            // Create an array of dictionaries which will show what was posted
            // This will not include any uploaded files. Those are handled above.
            var ary = [[String:Any]]()
            
            for (name, value) in params {
                ary.append([
                    "paramName":name,
                    "paramValue":value
                    ])
            }
            values["params"] = ary
            values["paramsCount"] = ary.count
        }
        
        values["title"] = "Upload Enumerator"
        contxt.extendValues(with: values)
        do {
            try contxt.requestCompleted(withCollector: collector)
        } catch {
            let response = contxt.webResponse
            response.status = .internalServerError
            response.appendBody(string: "\(error)")
            response.completed()
        }
    }
}
