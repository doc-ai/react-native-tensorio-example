//
//  TIOModelBundle.m
//  TensorIO
//
//  Created by Philip Dow on 7/20/18.
//  Copyright © 2018 doc.ai (http://doc.ai)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "TIOModelBundle.h"

#import "TIOModel.h"
#import "TIOModelOptions.h"
#import "TIOPlaceholderModel.h"
#import "TIOModelBackend.h"

NSString * const TIOTFModelBundleExtension = @"tfbundle";
NSString * const TIOModelBundleExtension = @"tiobundle";
NSString * const TIOModelInfoFile = @"model.json";
NSString * const TIOModelAssetsDirectory = @"assets";

@interface TIOModelBundle ()

@property (readwrite) NSDictionary *info;
@property (readwrite) NSString *path;

@property (readwrite) NSString *identifier;
@property (readwrite) NSString *name;
@property (readwrite) NSString *details;
@property (readwrite) NSString *author;
@property (readwrite) NSString *license;
@property (readwrite) BOOL quantized;

@property (readwrite) TIOModelOptions *options;
@property (readonly) NSString *modelClassName;

@end

@implementation TIOModelBundle

- (nullable instancetype)initWithPath:(NSString*)path {
    if (self = [super init]) {
        
        // Read json file
    
        NSString *jsonPath = [path stringByAppendingPathComponent:TIOModelInfoFile];
        NSData *data = [NSData dataWithContentsOfFile:jsonPath];
        
        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if ( json == nil ) {
            NSLog(@"Error reading json file at path %@, error %@", jsonPath, jsonError);
            return nil;
        }
        
        // Initialize
        
        _path = path;
        _info = json;
        
        _identifier = json[@"id"];
        _name = json[@"name"];
        _version = json[@"version"];
        _details = json[@"details"];
        _author = json[@"author"];
        _license = json[@"license"];
        
        _options = [[TIOModelOptions alloc] initWithDictionary:json[@"options"]];
        _quantized = [json[@"model"][@"quantized"] boolValue];
        _backend = json[@"model"][@"backend"];
        _type = json[@"model"][@"type"];
        
        _placeholder = json[@"placeholder"] != nil
                    && [json[@"placeholder"] boolValue] == YES;
    }
    
    return self;
}

- (NSString*)modelClassName {
    NSString *classname = _info[@"model"][@"class"];
    
    // If the model is a placeholder, use the placeholder class
    
    if ( self.placeholder ) {
        return @"TIOPlaceholderModel";
    }
    
    // Use model.class if it has been specified
    
    if ( classname != nil ) {
        return classname;
    }
    
    // Otherwise, use model.backend, and if none is specified, warn and use the available backend
    // If no backend is available, TIOAvailableBackend raises an exception
    
    if ( _backend == nil ) {
        NSLog(@"**** WARNING **** The model.json file must now specify which backend this model uses. "
              @"Add a \"backend\" field to the model dictionary in model.json, for example: "
              @"\n\"model\": {"
              @"\n  \"file\": \"model.tflite\","
              @"\n  \"backend\": \"tflite\""
              @"\n}");
        _backend = TIOAvailableBackend();
    }
    
    return TIOClassNameForBackend(_backend);
}

- (nullable id<TIOModel>)newModel {
    Class ModelClass = NSClassFromString(self.modelClassName);
    
    if ( ModelClass == nil ) {
        NSLog(@"Unable to convert model class name to class, %@", self.modelClassName);
        return nil;
    }
    
    id<TIOModel> model = [[ModelClass alloc] initWithBundle:self];
    
    if ( model == nil ) {
        NSLog(@"Unable to instantiate model for class %@", ModelClass);
        return nil;
    }

    return model;
}

- (NSString*)modelFilepath {
    if (self.isPlaceholder) {
        return nil;
    } else {
        return [_path stringByAppendingPathComponent:_info[@"model"][@"file"]];
    }
}

- (NSString*)pathToAsset:(NSString*)filename {
    return [[_path stringByAppendingPathComponent:TIOModelAssetsDirectory] stringByAppendingPathComponent:filename];
}

@end
