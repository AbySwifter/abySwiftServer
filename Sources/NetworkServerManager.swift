//
//  NetworkServerManager.swift
//  COpenSSL
//
//  Created by aby on 2018/6/4.
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectMustache

open class NetworkServerManager {
    fileprivate var server: HTTPServer
    
    internal init(root: String, port: UInt16) {
        server = HTTPServer.init()
        var routes = Routes.init(baseUri: "/api")
        configure(routes: &routes)                          //注册路由
        server.addRoutes(routes)                            //路由添加进服务
        server.serverPort = port                            //端口
        server.documentRoot = root                          //根目录
        server.setResponseFilters([(Filter404(), .high)])   //404过滤
        server.documentRoot = "./webroot"
    }
    open func startServer() {
        do {
            print("启动http服务器")
            try server.start()
        } catch PerfectError.networkError(let err, let msg) {
            print("网络出现错误：\(err), \(msg)")
        } catch {
            print("未知错误")
        }
    }
    //MARK: 通用响应格式
    func baseResponseBodyJSONData(status: Int, message: String, data: Any!) -> String {
        
        var result = Dictionary<String, Any>()
        result.updateValue(status, forKey: "status")
        result.updateValue(message, forKey: "message")
        if (data != nil) {
            result.updateValue(data, forKey: "data")
        }else{
            result.updateValue("", forKey: "data")
        }
        guard let jsonString = try? result.jsonEncodedString() else {
            return ""
        }
        return jsonString
    }

    //MARK: 404过滤
    struct Filter404: HTTPResponseFilter {
        
        func filterBody(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            callback(.continue)
        }
        
        func filterHeaders(response: HTTPResponse, callback: (HTTPResponseFilterResult) -> ()) {
            if case .notFound = response.status {
                response.setBody(string: "404 文件\(response.request.path)不存在。")
                response.setHeader(.contentLength, value: "\(response.bodyBytes.count)")
                callback(.done)
                
            } else {
                callback(.continue)
            }
        }
        
    }
}

// MARK: - 存放文件私有方法
extension NetworkServerManager {
    // MARK: 注册路由
    fileprivate func configure(routes: inout Routes) {
        // 添加接口，请求方式，路径
        routes.add(method: .get, uri: "/") { (request, response) in
            response.setHeader(.contentType, value: "text/html")
            let jsonDic = ["hello": "world"]
            let jsonString = self.baseResponseBodyJSONData(status: 200, message: "success", data: jsonDic)
            response.setBody(string: jsonString)//响应体
            response.completed()
        }
        
        routes.add(method: .get, uri: "/file/**") { (request, response) in
            let handler = StaticFileHandler.init(documentRoot: "./file", allowResponseFilters: true)
            request.path = request.urlVariables[routeTrailingWildcardKey] ?? "error.html"
            print("路径为\(request.path)")
            handler.handleRequest(request: request, response: response)
        }
        
        routes.add(method: .post, uri: "/upload") { (request, response) in
            let webRoot = request.documentRoot
            mustacheRequest(request: request, response: response, handler: UploadHandler(), templatePath: webRoot + "/response.mustache")
        }
    }
}
