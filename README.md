# 構築のポイント

- webサーバー
    
    nginxにてwebサーバー部分を作成する。
    
    webサーバーとしての主たる設定はリバースプロキシサーバーとしてapiサーバーへのルーティングを提供するものとする
    
    webコンテンツ部分はhtml,css,javascript(vanilla)を用いて
    
    簡易的なapiリクエストをボタンを押すことで実現可能な機構を作成する。
    
    javascriptにおいてはバックエンドとの通信を実施するためにfetchを使ったgetリクエスト、レスポンスの加工を実施する。
    
    htmlではjavascriptを起動させバックエンドへの司令をするボタンと、レスポンス内容が表示される画面を作成する。また、レスポンス内容を消去し画面をクリアに戻すためのボタンも設置する
    
    cssではこる必要はないがわかりやすいデザインとする
    
- apiサーバー
    
    golangのnet/httpライブラリを用いて、構築を実施する。
    
    8080番ポートでapiリクエストを任意のIPで待ち受ける
    
    CORS設定として任意のIP宛にすべてのメソッドを許可する
    
    ハンドラーに以下のパスパターンを登録する
    
    - /
        - helloworldの文字列を返す。
        - 単純にアプリケーションへのアクセスを試行して問題がないことを確認するため
    - /testapi
        - golang内で定義してある、構造体のサンプルデータをjson形式で返す
        - javascriptからのリクエストの受け口の一つ
        - webサーバーとapiサーバー間のデータ連携がうまくいっていることを確認するためにつかう
    - /dbapi(ここは次回)
        - dbのReservationテーブルに登録されたデータをjson形式で返す
        - javascriptからのリクエストの受け口の一つ
        - webサーバー→apiサーバー→db間のデータ連携がうまくいっていることを確認するために使う
    
    データベースとの接続のためのライブラリを用いてクエリを実行する
    
    クエリ用データはハンドラーからクエリ文字列で渡されたものを使用する
    
    クエリで受け取ったデータは構造体で定義済みの形に加工される
    
    構造体になったデータはjsonデータとしてエンコードされjavascriptに返される
    
    各パスパターンはgetメソッドにて処理がされる
    
    作成したコードからamazonlinux(amd)で使えるようにクロスコンパイルを実施してバイナリファイルのビルドを行う。
    
- Iac
    - terraformを使ってリソースのiac化を目指す
    - 特にmodule分けなどはせずに指定されたリソース情報を明記する
    - aws情報
        - ec2
            - keypair作成からawsへの連携までterraformで自動化して行う
            - ユーザーデータとterraformの変数埋め込みを駆使してterraformで動的にエンドポイントのipを取得する。
        - vpc
            - 要件に従ってterraform上でリソースを作成する。

# 主要パラメータ

## VPC

VPC名:

```jsx
reservation-vpc
```

cidr

```jsx
10.0.0.0/21
```

## subnet(webサーバー用)

name

```jsx
web-subnet-01
```

cidr

```jsx
10.0.0.0/24
```

route-table名

```jsx
web-routetable
```

## subnet(apiサーバー用)

名前

```jsx
api-subnet-01
```

cidr

```jsx
10.0.1.0/24
```

route-table名

```jsx
api-routetable
```

# igw

```jsx
reservation-ig
```

設定先

```jsx
api-routetable
web-routetable
```

# apiサーバー

```jsx
api-server-01
```

所属サブネット

```jsx
api-subnet-01
```

ami

```jsx
Amazon Linux 2023
```

sg

```jsx
inbound:
port80 all
port22 all 

```

作成方法

[https://github.com/CloudTechOrg/cloudtech-reservation-api/blob/main/documents/Sprint1_APIサーバの構築.md](https://github.com/CloudTechOrg/cloudtech-reservation-api/blob/main/documents/Sprint1_API%E3%82%B5%E3%83%BC%E3%83%90%E3%81%AE%E6%A7%8B%E7%AF%89.md)

# webサーバー

```jsx
web-server-01
```

所属サブネット

```jsx
web-subnet-01
```

ami

```jsx
Amazon Linux 2023
```

sg

```jsx
inbound:
port80 all
port22 all 

```

作成方法

[https://github.com/CloudTechOrg/cloudtech-reservation-web/blob/main/documents/Sprint1_Webサーバの構築.md](https://github.com/CloudTechOrg/cloudtech-reservation-web/blob/main/documents/Sprint1_Web%E3%82%B5%E3%83%BC%E3%83%90%E3%81%AE%E6%A7%8B%E7%AF%89.md)

# api サーバーのapiを作成してみる

goで簡単なAPIを返すだけの代物を作成

```jsx
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

type General struct {
	Message string `json:"message"`
}

func NewGeneral(message string) *General {
	return &General{Message: message}
}

func main() {

	r := mux.NewRouter()

	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"Content-Type", "Authorization"},
	})

	handler := c.Handler(r)

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, World!")
	}).Methods("GET")

	r.HandleFunc("/testapi", apiHandler).Methods("GET")

	log.Println("server start at port 8080")
	err := http.ListenAndServe(":8080", handler)
	if err != nil {
		log.Fatal(err)
	}
}

func apiHandler(w http.ResponseWriter, r *http.Request) {

	res := NewGeneral("Hello, World!@yamamoto desu")

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(res)
}

```

# apiを呼び出すwebコンテンツを作成してみる

html

```html
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <link rel="stylesheet" href="stylesheet.css">

</head>
<body>
    <header>
        <div class="container">
        <h1>test api@yamamoto</h1>
        </div>
    </header>
    <main>
    <div class="container">
        <button class="main-button" id="apiButton">GET api@plane</button>
        <button class="main-button" id="clearButton">clear</button>
        <div  class="response-area"id="apiResponse"></div>

    </div>
</main>
<footer>
    <div class="container">
        <p>footer</p>
    </div>
</footer>

<script src="index.js"></script>
</body>
</html>

```

css

```css
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: Arial, sans-serif;
}

header {
    background-color: #004444;
    color: #fff;
    padding: 20px 20px;
    
}

main {
    padding-top: 20px;
    padding-left:5%;
}

footer {
    padding-top: 20px;
    padding-left : 5%;
}

.main-button {
    border-radius: 8px;
    background-color:navy;
    color: white;
    font-size: 20px;
    border: solid 1px #000000;
    padding: 5px;

}

.response-area {
    width: 50%;
    height: 100px;
    border: solid 1px #000000;
    padding: 5px;
    margin-top: 10px;
}
```

js

```jsx
const apiButton = document.getElementById("apiButton");
const clearButton = document.getElementById("clearButton");
const apiResponse = document.getElementById("apiResponse");

apiButton.addEventListener("click", () => {
    fetch("http://localhost:8080/testapi")
        .then(response => response.json())
        .then(data => apiResponse.textContent = data.message);
});

clearButton.addEventListener("click", () => {
    apiResponse.textContent = "";
});
```
