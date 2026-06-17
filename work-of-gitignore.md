# Understanding .gitignore in a Go Project

A .gitignore file tells Git which files and folders it should ignore and not track when we run commands like:

```
git add .
git status
```

Without a .gitignore file, Git attempts to track every file in our project directory. However, not all files are worth storing in a repository. Many files are automatically generated during compilation, testing, or development and can be recreated whenever needed. Storing such files makes the repository larger, cluttered, and harder to maintain.

How it applies to our repository

Our repository contains:

```
├── .gitignore
├── LICENSE
├── README.md
├── go.mod
├── main.go
├── main_test.go
└── static/
```

All of these files are source files, configuration files, documentation, or project assets that should be tracked by Git. Therefore, none of them are ignored by the current .gitignore file.

The purpose of the .gitignore in this project is to prevent future generated files from being accidentally committed.

## Files ignored by our .gitignore
### 1. Executable Files
```
*.exe
*.exe~
```

When we build a Go application, Go may create executable files such as:
```
website.exe
app.exe
```

These executables are generated from our source code and can be recreated at any time using:
```
go build
```

Since they do not need to be stored in Git, they are ignored.

### 2. Shared Libraries
```
*.dll
*.so
*.dylib
```

These represent compiled libraries for different operating systems:

    - .dll → Windows
    - .so → Linux
    - .dylib → macOS

Since they are compiled artifacts and not source code, Git ignores them.

### 3. Go Test Binaries
```
*.test
```
Running:
```
go test -c
```
creates a compiled test executable such as:
```
main.test
```
This file is generated automatically and can always be recreated, so it is ignored.

### 4. Coverage Reports
```
*.out
```
When generating test coverage:
```
go test -coverprofile=coverage.out
```
Go creates:
```
coverage.out
```
This file contains testing statistics and is regenerated whenever tests are run. Therefore, it does not belong in source control.

### 5. Vendor Directory (Currently Not Ignored)
```
# vendor/
```
The # makes this line a comment.

Therefore:
```
vendor/
```
is not currently ignored.

If the # is removed:
```
vendor/
```
Git will ignore the entire vendor directory and all dependencies stored inside it.

### 6. Go Workspace Files
```
go.work
go.work.sum
```

These files are created when working with Go workspaces:
```
go work init
```

They are often specific to a developer's local environment and are therefore ignored.

Key Concept

A Git repository should primarily contain:

✅ Source code
```
main.go
main_test.go
```
✅ Project configuration
```
go.mod
```
✅ Documentation
```
README.md
LICENSE
```
✅ Static assets
```
HTML files
Images
```
A Git repository should generally avoid storing:

❌ Compiled executables
```
*.exe
```
❌ Compiled libraries
```
*.dll
*.so
*.dylib
```
❌ Test binaries
```
*.test
```
❌ Coverage reports
```
*.out
```
❌ Machine-specific workspace files
```
go.work
go.work.sum
```