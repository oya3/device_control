// dlltest.cpp : DLL アプリケーション用にエクスポートされる関数を定義します。
//
#include "stdafx.h"
#include <stdio.h>

// 以下の ifdef ブロックは DLL からのエクスポートを容易にするマクロを作成するための一般的な方法です。
// この DLL 内のすべてのファイルは、コマンド ラインで定義された 
//  WIN32PROJECT2_EXPORTS シンボル
// を使用してコンパイルされます。
// このシンボルは、この DLL を使用するプロジェクトでは定義できません。
// ソースファイルがこのファイルを含んでいる他のプロジェクトは、 
// WIN32PROJECT2_API 関数を DLL からインポートされたと見なすのに対し、この DLL は、このマクロで定義された
// シンボルをエクスポートされたと見なします。
#ifdef DLLTEST_EXPORTS
#define DLLTEST_API extern "C" __declspec(dllexport)
#else
#define DLLTEST_API extern "C" __declspec(dllimport)
#endif
 
DLLTEST_API int hello(void);
 
DLLTEST_API int hello(void) {
	printf("hello world\n");
	return 0;
}

DLLTEST_API int hello2(char *p) {
	printf("%s\n",p);
	return 0;
}

