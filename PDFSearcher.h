//
//  PDFSearcher.h
//  Reader
//
//  Created by ind558 on 03/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFSearcher : NSObject 
{
    CGPDFOperatorTableRef table;
    NSMutableString *currentData;
}
@property (nonatomic, retain) NSMutableString * currentData;
-(id)init;
-(BOOL)page:(CGPDFPageRef)inPage containsString:(NSString *)inSearchString;
@end