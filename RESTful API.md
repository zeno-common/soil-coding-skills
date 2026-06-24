# RESTful API 的设计原则（规范） 

规范文档：<https://restfulapi.net/>

# 前言

在主流公司的程序开发中，为了提高程序开发迭代的速度，基本都是前后端分离架构，而前端既包括网页、App、小程序等等，因此必须要有一个统一的规范用于约束前后端的通信，RESTful API则是目前比较成熟的API设计理论。

为了统一 web 服务的 http 接口设计风格，建立统一的一致性系统架构  `mental model` 。web  服务开发人员需要严格遵循以下约定。

# 简介

API 开发人员可以使用多种不同的架构设计 API。遵循 REST 架构风格的 API 称为 **REST API**。术语 RESTful API 通常指 RESTful Web API。术语 REST API 和 RESTful API 可以互换使用。

REST是 [Roy T. Fielding](https://link.juejin.cn?target=https%3A%2F%2Froy.gbiv.com%2F) 在其2000年的博士论文中提出的，是`Rpresentational State Transfer`词组的缩写，可以翻译为“表现层状态转移”，其实这个词组前面省略了个主语--“Resource”，加上主语后就是“资源表现层状态转移”。

**Resource（资源）**

所谓资源，就是互联网上的一个实体。URI（Uniform Resource Identifier）的全称就是统一资源标识符。一个资源可以是一段文字、一张图片、一段音频、一个服务。

**表现层（Representation）**

"资源"是一种信息实体，有多种外在表现形式。把"资源"具体呈现出来的形式，叫做它的"表现层"（Representation）。比如一篇文章，可以是XML、JSON、HTML的形式呈现出来。

**状态转移（State Transfer）**

访问一个网站，就代表了客户端和服务器的一个互动过程。在这个过程中，势必涉及到数据和状态的变化。互联网通信协议 `HTTP` 协议，是一个无状态协议，这意味着所有的状态都保存在服务器端。因此，如果客户端想要操作服务器，必须通过某种手段，让服务器端发生"状态转化"（State Transfer）。而这种转化是建立在表现层之上的，所以就是"表现层状态转化"。

# RESTful API 的设计原则（规范）

## 协议

协议是最基本的设计，表示前后端通信规范，现阶段应该使用`HTTPs`协议。

## 域名

`API`的根入口点应尽可能保持足够简单：

*   example.com/{domain\\_name}/\\* （主域名下）
    

域名应该考虑拓展性，将其放在主域名下，路径的第一个节点使用对应服务的领域名称这样可以保持一定的灵活性。

## 路径

路径又称为**端点**，表示 API 的具体地址。

在路径的设计中，需遵守下列约定：

1.  命名必须全部`小写`。
    
2.  资源（resource）的命名必须是`名词`，并且必须是`复数形式`。
    
    1.  命名必须全部小写和易读都无需解释，可以理解为规定。
        
    2.  命名必须是名词且需要复数形式。因为在RESTful中，主语是资源，资源是名词，不能是动词；并且一个资源往往对应数据库中一张表，表就是实体的集合，因此需要是复数形式。
        
3.  如果要使用连字符，建议使用‘-’而不是‘\__’，‘_’字符可能会在某些浏览器或屏幕中被部分遮挡或完全隐藏。
    
4.  不要在 URI 中使用未尾使用正斜杠（/）。如：<http://api.example.com/devices/>
    
5.  不要使用文件扩展名。
    
6.  不要在 URI 中使用 CRUD 函数名称。
    
7.  使用查询组件过滤 URI 集合。
    
    1.  例如：<http://api.example.com/devices?region=USA&brand=XYZ&sort=installation-date>
        

下面是一些反例：

*   api.example.com/user/getUser
    
*   api.example.com/user/addUser
    
*   api.example.com/user/devices/managed-devices.xml
    

下面是一些正例：

*   api.example.com/v1/zoos
    
*   api.example.com/v1/zoos/animal…
    

## HTTP verbs

对于如何操作资源，有相应的HTTP动词对应，常见的动词有如下五个（括号里表示SQL对应的命令）：

*   GET（SELECT）：从服务器取出资源（一项或多项）
    
*   POST（CREATE）：在服务器新建一个资源
    
*   PUT（UPDATE）：在服务器更新资源（客户端提供改变后的完整资源）
    
*   PATCH（UPDATE）：在服务器更新资源（客户端提供改变的属性）
    
*   DELETE（DELETE）：从服务器删除资源
    

示例：

| HTTP动词 | 路径 | 表述 |
| --- | --- | --- |
| GET | /v1/zoos | 获取所有动物园信息 |
| POST | /v1/zoos | 新建一个动物园 |
| GET | /v1/zoos/{id} | 获取指定动物园的信息 |
| PUT | /v1/zoos/{id} | 更新指定动物园的信息（前端提供该动物园的全部信息） |
| PATCH | /v1/zoos/{id} | 更新某个指定动物园的信息（提供该动物园改动部分的信息） |
| DELETE | /v1/zoos/{id} | 删除某个动物园 |
| GET | /v1/zoos/{id}/animals | 获取某个动物园里面的所有动物信息 |

### HTTP 方法的幂等性

设计 API 时遵循 REST 原则，自动提供幂等 REST API：

*   POST 不是幂等的。
    
*   GET、PUT、DELETE、HEAD、OPTIONS、TRACE 等等都是幂等的。**1. HTTP发布**
    

通常（不一定）API 用 POST 在服务器上创建新资源。

当执行相同的 POST 请求 N 次时，服务器上将有 N 个新资源。因此，POST 不是幂等的。

**2. HTTP GET， HEAD， OPTIONS 和 TRACE**

GET、HEAD、OPTIONS、TRACE 等方法永远不会更改服务器上的资源状态。它们纯粹用于检索该时间点的资源表示形式或元数据。

调用多个请求不会在服务器上进行任何写入操作，因此 GET、HEAD、OPTIONS 和 TRACE 是幂等的。

**3. HTTP PUT**

通常（不一定）API 用 PUT 更新资源状态。执行 API N 次，第1个请求将更新资源;其他的 N-1 请求只会一次又一次地覆盖相同的资源状态，实际上不会更改任何内容。因此，PUT是幂等的。

**4. 删除**

4.1. 使用资源标识符删除

当您执行 N 个相同的请求时：

（1）第1个请求将删除资源，并响应 `DELETE200 (OK)` 或  `204 (No Content)` 。

（2）其他 N-1 请求将返回 404（未找到）。响应与第一个请求不同，但服务器端的任何资源的状态都没有更改，因为原始资源已被删除。

因此：DELETE 是幂等的。

4.2. 不带资源标识符的删除

请记住，某些系统可能有如下删除 API：

```plaintext
DELETE /item/last
```

在上述情况下，调用操作 N 次将删除 N 个资源 – 因此在这种情况下不是幂等的。在这种情况下，一个好的建议可能是将上述 API 更改为 POST——因为 POST 不是幂等的。

```plaintext
POST /item/last
```

现在，这更接近HTTP规范 - 因此更符合REST。

## 过滤

如果数据量很大，服务器不可能将全部数据都返回给前端，因此前端需要提供一些参数进行过滤，用于分页展示或者排序等，下面是一些常见的参数：

*   ?limit=10：指定返回记录的数量
    
*   ?offset=10：指定返回记录的开始位置。
    
*   ?page=2\&pageSize=100：指定第几页，以及每页的记录数。
    
*   ?sortby=name\&order=asc：指定返回结果按照哪个属性排序，以及排序顺序。
    
*   ?animalTypeId=1：指定筛选条件
    

## HATEOAS (略，不支持)

HATEOAS 是 _Hypermedia As The Engine Of Application State_ 的缩写，从字面上理解是 _“超媒体即应用状态引擎”_ 。其原则就是客户端与服务器的交互完全由API动态提供，客户端**无需事先了解如何与服务器交互**，即返回结果中提供链接，连向其他API方法，使得用户不查文档，也知道下一步应该做什么。

例如，若要处理订单与客户之间的关系，可以在订单的表示形式中包含链接，用于指定下单客户可以执行的操作（查看客户信息、查看订单信息、删除订单等操作）。rel表示这个API与当前网址的关系，href表示API的路径，title 表示API的标题，type表示返回类型，action表示支持的操作类型。

```plaintext
{
  "orderID":3,
  "productID":2,
  "quantity":4,
  "orderValue":16.60,
  "links":[
     {
      "rel":"customer",
      "href":"https://adventure-works.com/customers/3",
      "action":"GET",
      "title":"get customer info",
      "types":["text/xml","application/json"]
    },
    {
      "rel":"self",
      "href":"https://adventure-works.com/orders/3",
      "action":"GET",
      "title":"get order info",
      "types":["text/xml","application/json"]
    }]
}
```

Github的API就是这种设计，访问[api.github.com](https://link.juejin.cn?target=https%3A%2F%2Fapi.github.com%2F)会得到一个所有可用API的网址列表。

```plaintext
{
  "current_user_url": "https://api.github.com/user",
  "emojis_url": "https://api.github.com/emojis",
  "events_url": "https://api.github.com/events",
  ......
}
```

## 版本控制

API一直保持静态的可能性很小，随着业务需求变化，可能会添加新的资源，底层的数据结构可能也会有更改。在更新API提供新功能的同时，需要考虑对已使用该API用户的影响，因此需要保持向前兼容，这就引出了版本控制。主要的版本控制方法有如下几种：

1.  **URI版本管理**每次修改 Web API 或更改资源的架构时，向每个资源的 URI 添加版本号。 以前存在的 URI 应像以前一样继续运行，并返回符合原始架构的资源。
    

```plaintext
api.example.com/v1/*
api.example.com/v2/*
```

该方法的版本控制机制非常简单，但是随着 API 多次迭代，服务器需要支持多个版本的路由，增大了维护的成本。 此方案也增加了 HATEOAS 实现的复杂性，因为所有链接都需要在其 URI 中包括版本号。

1.  **查询字符串版本控制 （麻烦）**不是提供多个 URI，而是通过在追加查询字符串的方式来指定版本，例如 `https://adventure-works.com/customers/3?version=2`。 如果 version 参数被较旧的客户端应用程序省略，则应默认为有意义的值（例如 1）。
    

此方法具有语义优势（即，同一资源始终从同一 URI 进行检索），但它依赖于代码处理请求以分析查询字符串并发送回相应的 HTTP 响应。 该方法也与 URI 版本控制机制一样，增加了实现 HATEOAS 的复杂性。

1.  **自定义请求标头进行版本控制 （不直观）**在请求的header中自定义版本控制选项。
    

```plaintext
GET https://adventure-works.com/customers/3 HTTP/1.1
Custom-Header: api-version=1
```

1.  **Accept标头进行版本控制(复杂)**当客户端应用程序向 Web 服务器发送 HTTP GET 请求时，可以 Accept 标头规定它可以处理的内容的格式。 通常，_Accept_ 标头的用途是客户端指定响应的正文应是 XML、JSON 或者其他可处理的的格式。 但是，我们也可以指定该标头为使客户端需要的资源版本。
    

```plaintext
GET https://adventure-works.com/customers/3 HTTP/1.1
Accept: application/vnd.adventure-works.v1+json
```

上例将 _Accept_ 标头指定为 _application/vnd.adventure-works.v1+json_。 _vnd.adventure-works.v1_ 元素向 Web 服务器指示它应返回资源的版本 v1，而 _json_ 元素则指定响应正文的格式应为 JSON。

此方法可以说是最纯粹的版本控制机制并自然地适用于 HATEOAS，后者可以在资源链接中包含相关数据的 MIME 类型。

在现实世界中，API永远不会完全稳定。因此，如何管理这一变化非常重要。对于大多数API而言，商定好部分版本的控制策略，然后对API详细记录和逐步弃用是可接受的做法。

## 服务端响应

API响应，**需要遵守HTTP设计规范，选择合适的状态码返回。你可能见过有的接口始终返回状态码200，然后通过返回体中的code字段进行区分请求是否成功，这种是不符合规范的，相当于状态码没有了任何作用，下面就是**一个反例。

```plaintext
HTTP/1.1 200 ok
Content-Type: application/json
Server: example.com

{ "errCode": -1,"errDesc": "该活动不存在" }
```

其次，在出现错误时，需要返回错误信息，常见的返回方式就是放在返回体中。

```plaintext
HTTP/1.1 401 Unauthorized
Server: nginx/1.11.9
Content-Type: application/json
Transfer-Encoding: chunked
Cache-Control: no-cache, private
Date: Sun, 24 Jun 2018 10:02:59 GMT
Connection: keep-alive

{"error_code":40100,"message":"Unauthorized"}
```

## 状态码

HTTP状态码由三个十进制数字组成，第一个十进制数字定义了状态码的类型，HTTP状态码共分为5种类型：

| 分类 | 描述 |
| --- | --- |
| 1xx | 信息，服务器收到请求，需要请求者继续执行操作 |
| 2xx | 成功，操作被成功接收并处理 |
| 3xx | 重定向，需要进一步的操作以完成请求 |
| 4xx | 客户端错误，请求包含语法错误或无法完成请求 |
| 5xx | 服务器错误，服务器在处理请求的过程中发生了错误 |

API不需要1xx类型的状态码，因此我们主要看下其他几个类型常见的状态码：

1.  **2xx状态码** | 状态码 | 英文名称       | 描述                                                                                     || :-- | :--------- | :------------------------------------------------------------------------------------- || 200 | OK         | 请求成功，一般用于GET和POST请求                                                                    || 201 | Created    | 请求成功并创建了新的资源，用于POST、PUT、PATCH请求。例如新增用户、修改用户信息等，同时在返回体中，我们既可以返回创建后实体的所有信息数据，也可以不返回相关信息。 || 202 | Accepted   | 已接受请求，但未处理完成，会在未来再处理，通常用于异步操作                                                          || 204 | No Content | 该状态码表示响应实体不包含任何数据，使用DELETE进行删除操作时，需返回该状态码                                              |
    
2.  **3xx状态码**API 用不到301状态码（永久重定向）和302状态码（暂时重定向，307也是这个含义），因为它们可以由应用级别返回，浏览器会直接跳转，API 级别可以不考虑这两种情况。
    

API 用到的3xx状态码，主要是303 See Other，表示参考另一个 URL。它与302和307的含义一样，也是"暂时重定向"，区别在于302和307用于GET请求，而303用于POST、PUT和DELETE请求。收到303以后，浏览器不会自动跳转，而会让用户自己决定下一步怎么办。

下面是一个例子。

```plaintext
HTTP/1.1 303 See Other
Location: /api/orders/12345
复制代码
```

1.  **4xx状态码** | 状态码 | 英文名称                   | 描述                                                                             || :-- | :--------------------- | :----------------------------------------------------------------------------- || 400 | Bad Request            | 客户端请求的语法错误，服务器无法理解                                                             || 401 | Unauthorized           | 表示用户没有权限（令牌、用户名、密码错误）                                                          || 403 | Forbidden              | 没有权限访问该请求，服务器收到请求但拒绝提供服务                                                       || 404 | Not Found              | 服务器无法根据客户端的请求找到资源（如路径不存在）                                                      || 405 | Method Not Allowed     | 客户端请求的方法服务端不支持，例如使用 POST 方法请求只支持 GET 方法的接口                                     || 406 | Not Acceptable         | 用户GET请求的格式不可得（比如用户请求 JSON 格式，但是只有 XML 格式）                                      || 408 | Request Time-out       | 客户端请求超时                                                                        || 410 | Gone                   | 客户端GET请求的资源已经不存在。410 不同于 404，如果资源以前有现在被永久删除了可使用410 代码，网站设计人员可通过 301 代码指定资源的新位置 || 415 | Unsupported Media Type | 通常表示服务器不支持客户端请求首部 Content-Type 指定的数据格式。如在只接受 JSON 格式的 API 中放入 XML 类型的数据并向服务器发送 || 429 | Too Many Requests      | 客户端的请求次数超过限额                                                                   |
    
2.  **5xx状态码**5xx状态码表示服务端错误。一般来说，API 不会向用户透露服务器的详细信息，所以只要两个状态码就够了。
    

| 状态码 | 英文名称 | 描述 |
| --- | --- | --- |
| 500 | Internal Server Error | 客户端请求有效，服务器处理时发生了意外 |
| 503 | Service Unavailable | 服务器无法处理请求，一般用于网站维护状态 |

## 5xx 状态代码（服务器错误）

| 状态代码 | 描述 |
| --- | --- |
| 500 内部服务器错误 | 服务器遇到意外情况，阻止它完成请求。 |
| 501 未实现 | 服务器不支持 HTTP 方法，无法处理。 |
| 502 错误的网关 | 服务器在充当网关以获取处理请求所需的响应时收到无效响应。 |
| 503 服务不可用 | 服务器尚未准备好处理请求。 |
| 504 网关超时 | 服务器充当网关，无法及时获得请求的响应。 |
| 不支持 505 HTTP 版本（实验性） | 服务器不支持请求中使用的 HTTP 版本。 |
| 506变体也协商（实验性） | 指示服务器存在内部配置错误：所选变体资源配置为本身参与透明内容协商，因此不是协商过程中的适当终结点。 |
| 507 存储空间不足 （WebDAV） | 无法对资源执行该方法，因为服务器无法存储成功完成请求所需的表示形式。 |
| 检测到 508 个环路 （WebDAV） | 服务器在处理请求时检测到无限循环。 |
| 510 未扩展 | 服务器需要进一步扩展请求才能完成请求。 |
| 511 需要网络身份验证 | 指示客户端需要进行身份验证才能获得网络访问权限。 |