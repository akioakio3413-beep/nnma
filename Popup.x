#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

// ユーザー設定に「次回から表示しない」状態を保存するキー
#define DontShowAlertAgain @"KEY_12345"

BOOL QxUsesJapaneseLanguage() {
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    return [language hasPrefix:@"ja"];
}

UIImage* roundedIconImage(UIImage *image, CGSize newSize) {
    if (!image) {
        return nil;
    }

    CGRect bounds = CGRectMake(0, 0, newSize.width, newSize.height);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, image.scale);
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:newSize.width * 0.2];
    [clipPath addClip];
    [image drawInRect:bounds];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return roundedImage;
}

// X の画像がまだダウンロードできていない時の予備アイコン
UIImage* createXFallbackImage(CGSize size) {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *background = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:size.width * 0.2];
    [[UIColor blackColor] setFill];
    [background fill];

    UIBezierPath *xPath = [UIBezierPath bezierPath];
    xPath.lineWidth = size.width * 0.12;
    xPath.lineCapStyle = kCGLineCapButt;
    [xPath moveToPoint:CGPointMake(size.width * 0.32, size.height * 0.25)];
    [xPath addLineToPoint:CGPointMake(size.width * 0.70, size.height * 0.75)];
    [xPath moveToPoint:CGPointMake(size.width * 0.70, size.height * 0.25)];
    [xPath addLineToPoint:CGPointMake(size.width * 0.32, size.height * 0.75)];
    [[UIColor whiteColor] setStroke];
    [xPath stroke];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// MediaFire の画像がまだダウンロードできていない時の予備アイコン
UIImage* createMediaFireFallbackImage(CGSize size) {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *background = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:size.width * 0.2];
    [[UIColor colorWithRed:0.0 green:0.46 blue:0.92 alpha:1.0] setFill];
    [background fill];

    NSString *text = @"MF";
    NSDictionary *attributes = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:size.width * 0.32],
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake((size.width - textSize.width) / 2.0,
                                 (size.height - textSize.height) / 2.0,
                                 textSize.width,
                                 textSize.height);
    [text drawInRect:textRect withAttributes:attributes];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Mirrativ の画像がまだダウンロードできていない時の予備アイコン
UIImage* createMirrativFallbackImage(CGSize size) {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    UIBezierPath *background = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:size.width * 0.2];
    [[UIColor colorWithRed:0.03 green:0.72 blue:0.74 alpha:1.0] setFill];
    [background fill];

    UIBezierPath *badge = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(size.width * 0.62,
                                                                            size.height * 0.62,
                                                                            size.width * 0.28,
                                                                            size.height * 0.28)];
    [[UIColor colorWithRed:0.0 green:0.55 blue:0.57 alpha:0.75] setFill];
    [badge fill];

    NSString *text = @"M";
    UIFont *mirrativFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:size.width * 0.26];
    if (!mirrativFont) {
        mirrativFont = [UIFont systemFontOfSize:size.width * 0.26 weight:UIFontWeightLight];
    }
    NSDictionary *attributes = @{
        NSFontAttributeName: mirrativFont,
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake(size.width * 0.62 + (size.width * 0.28 - textSize.width) / 2.0,
                                 size.height * 0.62 + (size.height * 0.28 - textSize.height) / 2.0,
                                 textSize.width,
                                 textSize.height);
    [text drawInRect:textRect withAttributes:attributes];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// 画像をダウンロードして Documents/cookie/ に保存する
// アプリ起動時に実行される
void downloadAndSaveImages() {
    // ダウンロードする画像のURL
    NSString *xImageURL = @"https://is1-ssl.mzstatic.com/image/thumb/Purple211/v4/21/c4/b3/21c4b30e-348c-1eda-837b-8ec0e659ee4c/ProductionAppIcon-0-0-1x_U007emarketing-0-8-0-0-0-85-220.png/512x512bb.jpg";
    NSString *mfImageURL = @"https://is1-ssl.mzstatic.com/image/thumb/Purple115/v4/1a/d0/69/1ad06903-39d6-192a-db8d-f06d6ad42c74/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/512x512bb.jpg";
    NSString *mirrativImageURL = @"https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/16/1a/b5/161ab585-2154-8418-84ec-a2e40dff6b74/AppIcon-0-0-1x_U007epad-0-1-0-85-220.png/512x512bb.jpg";

    // Documents ディレクトリのパスを取得し、cookie サブフォルダを用意する
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *cookieImagesPath = [documentsDirectory stringByAppendingPathComponent:@"cookie"];

    // cookie ディレクトリが存在しない場合は作成する
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:cookieImagesPath]) {
        NSError *error;
        if ([fileManager createDirectoryAtPath:cookieImagesPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        }
    }

    // ダウンロード対象の画像設定
    NSArray *imageInfos = @[
        @{@"url": xImageURL, @"name": @"x.jpg"},
        @{@"url": mfImageURL, @"name": @"mf.jpg"},
        @{@"url": mirrativImageURL, @"name": @"mirrativ.jpg"}
    ];

    // 各画像を処理する
    for (NSDictionary *imageInfo in imageInfos) {
        NSString *imageURL = imageInfo[@"url"];
        NSString *imagePath = [cookieImagesPath stringByAppendingPathComponent:imageInfo[@"name"]];
        
        // ローカルに画像が存在しない場合のみダウンロードする
        if (![fileManager fileExistsAtPath:imagePath]) {
            NSURL *url = [NSURL URLWithString:imageURL];
            
            if (!url) {
                continue;
            }
            
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (error == nil) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    
                    if (httpResponse.statusCode == 200) {
                        NSError *moveError;
                        if ([[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:imagePath] error:&moveError]) {
                        }
                    }
                }
            }];
            
            [downloadTask resume];
        }
    }
}

// アラートを表示するメイン処理
void QxAlert() {
    // ユーザーが「次回から表示しない」を選択していないか確認する
    if (![[NSUserDefaults standardUserDefaults] boolForKey:DontShowAlertAgain]) {
        BOOL usesJapanese = QxUsesJapaneseLanguage();
        NSString *alertTitle = usesJapanese ? @"ようこそ" : @"Welcome";
        NSString *alertMessage = usesJapanese ? @"開きたいリンクを選択してください。" : @"Select a link to open.";
        NSString *dontShowTitle = usesJapanese ? @"次回から表示しない" : @"Don't show again";
        NSString *closeTitle = usesJapanese ? @"閉じる" : @"Close";

        // 保存済み画像のパスを取得する
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths firstObject];
        NSString *cookieImagesPath = [documentsDirectory stringByAppendingPathComponent:@"cookie"];

        // ローカルストレージから画像を読み込む
        UIImage *xImage = [UIImage imageWithContentsOfFile:[cookieImagesPath stringByAppendingPathComponent:@"x.jpg"]];
        UIImage *mfImage = [UIImage imageWithContentsOfFile:[cookieImagesPath stringByAppendingPathComponent:@"mf.jpg"]];
        UIImage *mirrativImage = [UIImage imageWithContentsOfFile:[cookieImagesPath stringByAppendingPathComponent:@"mirrativ.jpg"]];
        if (!xImage) {
            xImage = createXFallbackImage(CGSizeMake(30, 30));
        }
        if (!mfImage) {
            mfImage = createMediaFireFallbackImage(CGSizeMake(30, 30));
        }
        if (!mirrativImage) {
            mirrativImage = createMirrativFallbackImage(CGSizeMake(30, 30));
        }

        // 画像を 30x30 ピクセルにリサイズする
        UIImage *resizedXImage = roundedIconImage(xImage, CGSizeMake(30, 30));
        UIImage *resizedMfImage = roundedIconImage(mfImage, CGSizeMake(30, 30));
        UIImage *resizedMirrativImage = roundedIconImage(mirrativImage, CGSizeMake(30, 30));

        // デバイスに応じてアラートの表示スタイルを決定する
        UIAlertControllerStyle alertStyle = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) 
            ? UIAlertControllerStyleActionSheet  // iPhone 向け
            : UIAlertControllerStyleAlert;       // iPad 向け

        // タイトルとメッセージ付きの UIAlertController を作成する
        UIAlertController *view = [UIAlertController alertControllerWithTitle:alertTitle
                                                                     message:alertMessage
                                                              preferredStyle:alertStyle];

        // 「X」ボタンを黒で表示する
        UIAlertAction* x = [UIAlertAction actionWithTitle:@"X"
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
                                                     NSURL *url = [NSURL URLWithString:@"https://x.com/s_cookie2"];
                                                     if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                                         [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                     }
                                                     [view dismissViewControllerAnimated:YES completion:nil];
                                                 }];
        [x setValue:[UIColor blackColor] forKey:@"titleTextColor"];

        // 「Mediafire」ボタンを青で表示する
        UIAlertAction* mediafire = [UIAlertAction actionWithTitle:@"Mediafire"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             NSURL *url = [NSURL URLWithString:@"https://www.mediafire.com/folder/l3nk6x2b9uyep/"];
                                                             if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                                                 [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                             }
                                                             [view dismissViewControllerAnimated:YES completion:nil];
                                                         }];
        [mediafire setValue:[UIColor colorWithRed:0.0 green:0.46 blue:0.92 alpha:1.0] forKey:@"titleTextColor"];

        // 「Mirrativ」ボタンをティールで表示する
        UIAlertAction* mirrativ = [UIAlertAction actionWithTitle:@"Mirrativ"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            NSURL *url = [NSURL URLWithString:@"https://www.mirrativ.com/user/146200001"];
                                                            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                                                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                            }
                                                            [view dismissViewControllerAnimated:YES completion:nil];
                                                        }];
        [mirrativ setValue:[UIColor colorWithRed:0.03 green:0.72 blue:0.74 alpha:1.0] forKey:@"titleTextColor"];

        // 「次回から表示しない」ボタンをオレンジで表示する
        UIAlertAction* dontShowAgain = [UIAlertAction actionWithTitle:dontShowTitle
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DontShowAlertAgain];
                                                                [[NSUserDefaults standardUserDefaults] synchronize];
                                                                [view dismissViewControllerAnimated:YES completion:nil];
                                                            }];
        [dontShowAgain setValue:[UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0] forKey:@"titleTextColor"];

        // 指定順にアクションをアラートに追加する
        [view addAction:x];
        [view addAction:mediafire];
        [view addAction:mirrativ];
        [view addAction:dontShowAgain];

        // 「閉じる」ボタンをキャンセルスタイルと赤色で表示する
        UIAlertAction* done = [UIAlertAction actionWithTitle:closeTitle
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       [view dismissViewControllerAnimated:YES completion:nil];
                                                   }];
        [done setValue:[UIColor redColor] forKey:@"titleTextColor"];
        [view addAction:done];

        // リサイズ済み画像を各ボタンに割り当てる
        [x setValue:[resizedXImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
        [mediafire setValue:[resizedMfImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
        [mirrativ setValue:[resizedMirrativImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];

        // ルートビューコントローラを取得してアラートを表示する
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        UIViewController *rootViewController = keyWindow.rootViewController;
        [rootViewController presentViewController:view animated:YES completion:nil];
    }
}

// ライブラリ読み込み時に自動実行される初期化処理
__attribute__((constructor))
static void init() {
    // 画像のダウンロードを開始する
    downloadAndSaveImages();

    // ***注意: 画像がダウンロードされない、またはローカルから読み込めない場合は、
    // 画像なしの通常ボタンとしてアラートが表示される。***

    // 4秒待ってからアラートを表示する
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        QxAlert();
    });
}
